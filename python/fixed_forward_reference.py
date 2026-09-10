import numpy as np
from pathlib import Path

from torchvision.datasets import MNIST

PROJECT_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = PROJECT_DIR / "data"
WEIGHTS_DIR = PROJECT_DIR / "weights"
RESULTS_DIR = PROJECT_DIR / "results"

DATA_DIR.mkdir(parents=True, exist_ok=True)
WEIGHTS_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


#configs
SEED = 42
NUM_INPUTS = 28 * 28
NUM_OUTPUTS = 10
TEST_LIMIT = 10_000

#accumulator shifts to be tested for exp A
ACC_SHIFTS = range(8, 19)
INTEGER_TRAIN_LIMIT = 10_000

#experiment B
TRAIN_ACC_SHIFT = 9
#scale weight update
TRAIN_SHIFTS = range(15, 23)

def signed_shift_toward_zero(values, shift):
    """
    divide signed integers by 2**shift
    """
    values = np.asarray(
        values,
        dtype=np.int64 #use 64 to avoid overflow
    )
    magnitude = np.abs(values) >> shift
    return np.where( #normal arithmetic right shift behaves strangely around zero
        values < 0,
        -magnitude,
        magnitude
    )

#plan POSITIVE activation
def plan_positive(a):
    a = np.asarray(a, dtype=np.int64)
    y = np.zeros_like(a)

    # a >= 160
    mask = a >= 160
    y[mask] = 32
    # 76 <= a < 160
    mask = (a >= 76) & (a < 160)
    y[mask] = (a[mask] >> 5) + 27
    # 32 <= a < 76
    mask = (a >= 32) & (a < 76)
    y[mask] = (a[mask] >> 3) + 20
    # 0 <= a < 32
    mask = (a >= 0) & (a < 32)
    y[mask] = (a[mask] >> 2) + 16

    return y

#FPGA-style PLAN activation.
def plan(a):
    a = np.asarray(a, dtype=np.int64)
    a = np.clip( a, -256, 255)
    abs_a = np.abs(a)
    positive = plan_positive(abs_a)
    #sigmoid(-x) = 1 - sigmoid(x)
    #PLAN(-x) = 32 - PLAN(x)

    y = np.where(
        a >= 0,
        positive,
        32 - positive,
    )
    return y


#mnist load
print("Loading MNIST...")
train_dataset = MNIST(root=DATA_DIR, train=True, download=True)
test_dataset = MNIST(root=DATA_DIR, train=False, download=True)

#im->numpy normalize to 0.0...1.0
train_images_float = train_dataset.data[:INTEGER_TRAIN_LIMIT].numpy().astype(np.float32) / 255.0
train_labels = train_dataset.targets[:INTEGER_TRAIN_LIMIT].numpy()

test_images_float = test_dataset.data[:TEST_LIMIT].numpy().astype(np.float32) / 255.0
test_labels = test_dataset.targets[:TEST_LIMIT].numpy()

#28x28 -> 784
train_images_float = train_images_float.reshape(-1, NUM_INPUTS)
test_images_float = test_images_float.reshape(-1, NUM_INPUTS)

#1)quantize pixels 0/1->0/127
train_images = np.round(
    train_images_float * 127.0
).astype(np.int64)

test_images = np.round(
    test_images_float * 127.0
).astype(np.int64)

print("Training data:", train_images.shape)
print("Testing data:", test_images.shape)
print("Integer pixel range:", train_images.min(), "...", train_images.max())


#load float weights from previous training
float_weights_file = (
    WEIGHTS_DIR
    / "float_weights.npy"
)
if not float_weights_file.exists():
    raise FileNotFoundError(
        "float_weights.npy was not found. "
        "Run float_reference.py first."
    )
float_weights = np.load(
    float_weights_file
)
print("Loaded floating-point weights:")
print(float_weights.shape)

#stats print
print()
print("Floating-point weight statistics:")
print(f"min = {float_weights.min():.6f}")
print(f"max = {float_weights.max():.6f}")

max_abs_weight = np.max(np.abs(float_weights))
print(f"max abs = {max_abs_weight:.6f}")

#2)quantize trained weights to signed 8-bit
weight_scale = 127.0 / max_abs_weight #22

int_weights_from_float = np.round(float_weights * weight_scale).astype(np.int64)
int_weights_from_float = np.clip(
    int_weights_from_float,
    -127,
    127,
)

print() #-127...105
print("8-bit weight quantization:")
print(f"scale = {weight_scale:.6f}")
print(f"integer min = {int_weights_from_float.min()}")
print(f"integer max = {int_weights_from_float.max()}")

#3) integer weighted sums !!!
accumulators = (
    test_images
    @ int_weights_from_float.T
)
print()
print("Raw accumulator statistics:")
print(f"minimum = {accumulators.min()}")
print(f"maximum = {accumulators.max()}")

#accuracy before PLAN
raw_predictions = np.argmax(accumulators, axis=1)
raw_accuracy = np.mean(raw_predictions == test_labels)
print()
print(
    "Quantized integer accuracy "
    f"before PLAN: "
    f"{raw_accuracy * 100:.2f}%"
)

# Find ACC_SHIFT
print()
print("ACC_SHIFT sweep")
acc_results = []
best_acc_accuracy = -1.0
best_acc_shift = None


for shift in ACC_SHIFTS:
    scaled = (
        accumulators
        >> shift
    )

    #overflows
    below_range = np.mean(
        scaled < -256
    )
    above_range = np.mean(
        scaled > 255
    )
    saturation_rate = below_range + above_range

    #saturate to PLAN input range
    plan_input = np.clip(
        scaled,
        -256,
        255,
    )

    #PLAN activation.
    outputs = plan(plan_input)
    predictions = np.argmax(outputs, axis=1)
    accuracy = np.mean(predictions == test_labels)


    #ties (same output for both predictions)
    maximum = np.max(
        outputs,
        axis=1,
        keepdims=True,
    )
    tie_count = np.sum(outputs == maximum, axis=1)
    tie_rate = np.mean(tie_count > 1)
    print(
        f"shift={shift:2d} | "
        f"accuracy={accuracy * 100:6.2f}% | "
        f"saturation={saturation_rate * 100:6.2f}% | "
        f"ties={tie_rate * 100:6.2f}%"
    )

    acc_results.append((shift, accuracy, saturation_rate, tie_rate))
    if accuracy > best_acc_accuracy:
        best_acc_accuracy = accuracy
        best_acc_shift = shift #10


# =========================================================
# Selected ACC_SHIFT
# =========================================================

print()
print("Best fixed-point forward configuration")
print(f"ACC_SHIFT = {best_acc_shift}")
print(f"Accuracy  = {best_acc_accuracy * 100:.2f}%")
#results save
np.save(WEIGHTS_DIR  / "int8_weights_from_float.npy", int_weights_from_float)
np.savetxt(
    RESULTS_DIR
    / "fixed_forward_shift_sweep.csv",
    np.array(acc_results),
    delimiter=",",
    header=(
        "acc_shift,"
        "accuracy,"
        "saturation_rate,"
        "tie_rate"
    ),
    comments="",
)


#exp B
#direct integer training
def integer_forward(
    weights,
    image,
    acc_shift,
):
    """
    returns:
        prediction
        10 PLAN outputs
    """
    accumulator = (
        weights
        @ image
    )
    plan_input = (
        accumulator
        >> acc_shift
    )
    plan_input = np.clip(
        plan_input,
        -256,
        255,
    )
    outputs = plan(
        plan_input
    )
    prediction = int(
        np.argmax(outputs)
    )
    return prediction, outputs


#integer forward evaluation for many images
def evaluate_integer(
    weights,
    images,
    labels,
    acc_shift,
):
    accumulators = (
        images
        @ weights.T
    )
    plan_input = (
        accumulators
        >> acc_shift
    )
    plan_input = np.clip(
        plan_input,
        -256,
        255,
    )
    outputs = plan(
        plan_input
    )
    predictions = np.argmax(
        outputs,
        axis=1,
    )
    return np.mean(
        predictions
        == labels
    )

print()
print("Integer training TRAIN_SHIFT sweep")
rng = np.random.default_rng(SEED)


#the paper says weights are initialized randomly. But we want to avoid immediate saturation
initial_float_weights = rng.uniform(
    low=-0.05,
    high=0.05,
    size=(
        NUM_OUTPUTS,
        NUM_INPUTS,
    ),
)
initial_weights = np.round(
    initial_float_weights * 128.0
).astype(np.int64)
initial_weights = np.clip(initial_weights, -128, 127)

print( #-6...6
    "Initial integer weight range:",
    initial_weights.min(),
    "...",
    initial_weights.max()
)


train_results = []
best_train_accuracy = -1.0
best_train_shift = None
best_train_weights = None

for train_shift in TRAIN_SHIFTS:
    print()
    print( f"Training with TRAIN_SHIFT= {train_shift}")
    weights = (
        initial_weights.copy()
    )

    #online training
    for sample_index in range(INTEGER_TRAIN_LIMIT):
        image = (
            train_images[sample_index]
        )
        label = (
            train_labels[sample_index]
        )
        #forward prop
        prediction, outputs = (
            integer_forward(
                weights,
                image,
                TRAIN_ACC_SHIFT,
            )
        )

        # correct neuron   = 32
        # incorrect neuron = 0
        target = np.zeros(
            NUM_OUTPUTS,
            dtype=np.int64,
        )
        target[label] = 32
        #error
        error = target - outputs

        #sigmoid gradient
        gradient = (
            outputs * (32 - outputs)
        )
        # Neuron correction
        correction = (
            error
            * gradient
        )
        #weight update
        delta_weights = np.outer(
            correction,
            image
        )
        #fixed-point / learning-rate scaling
        #use symmetric truncation toward zero instead of Python's arithmetic right shift.
        delta_weights = signed_shift_toward_zero(
            delta_weights,
            train_shift
        )
        weights += delta_weights
        weights = np.clip(
            weights,
            -128,
            127
        )

    #evaluate this training configuration
    accuracy = evaluate_integer(
        weights,
        test_images,
        test_labels,
        TRAIN_ACC_SHIFT,
    )
    saturated_weights = np.mean(
        (weights == -128) | (weights == 127)
    )
    zero_weights = np.mean(
        weights == 0
    )
    approx_learning_rate = 2.0 ** (
        15 - train_shift
    )

    print(
        f"TRAIN_SHIFT={train_shift:2d} | "
        f"eta≈{approx_learning_rate:.4f} | "
        f"accuracy={accuracy * 100:6.2f}% | "
        f"saturated={saturated_weights * 100:6.2f}% | "
        f"zero={zero_weights * 100:6.2f}%"
    )


    train_results.append(
        (
            train_shift,
            accuracy,
            saturated_weights,
            zero_weights
        )
    )
    if accuracy > best_train_accuracy:
        best_train_accuracy = (
            accuracy
        )
        best_train_shift = (
            train_shift
        )
        best_train_weights = (
            weights.copy()
        )
#final evaluation of best integer training configuration
print()
print("Best integer-training configuration")
print(f"TRAIN_SHIFT = {best_train_shift}")
print(f"Accuracy    = {best_train_accuracy * 100:.2f}%")
# save results
np.savetxt(
    RESULTS_DIR
    / "integer_training_shift_sweep.csv",
    np.array(train_results),
    delimiter=",",
    header=(
        "train_shift,"
        "accuracy,"
        "saturated_weights,"
        "zero_weights"
    ),
    comments="",
)
np.save(
    WEIGHTS_DIR
    / "integer_trained_weights_10000.npy",
    best_train_weights,
)


#final fix-point parameters
with open(
    RESULTS_DIR
    / "fixed_parameters.txt",
    "w",
) as f:
    f.write(
        f"ACC_SHIFT={best_acc_shift}\n"
    )
    f.write(
        f"TRAIN_SHIFT={best_train_shift}\n"
    )
    f.write(
        f"WEIGHT_SCALE={weight_scale}\n"
    )
    f.write(
        f"FIXED_FORWARD_ACCURACY="
        f"{best_acc_accuracy}\n"
    )
    f.write(
        f"INTEGER_TRAINING_ACCURACY="
        f"{best_train_accuracy}\n"
    )
print()
print("Saved:")
print(
    WEIGHTS_DIR
    / "int8_weights_from_float.npy"
)
print(
    WEIGHTS_DIR
    / "integer_trained_weights_10000.npy"
)
print(
    RESULTS_DIR
    / "fixed_forward_shift_sweep.csv"
)
print(
    RESULTS_DIR
    / "integer_training_shift_sweep.csv"
)
print(
    RESULTS_DIR
    / "fixed_parameters.txt"
)