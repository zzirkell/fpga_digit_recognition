import numpy as np
from pathlib import Path

from torchvision.datasets import MNIST


# =========================================================
# Project paths
# =========================================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = PROJECT_DIR / "data"
WEIGHTS_DIR = PROJECT_DIR / "weights"
RESULTS_DIR = PROJECT_DIR / "results"

DATA_DIR.mkdir(parents=True, exist_ok=True)
WEIGHTS_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


# =========================================================
# Configuration
# =========================================================

SEED = 42

NUM_INPUTS = 28 * 28
NUM_OUTPUTS = 10

TEST_LIMIT = 10_000

# Accumulator scaling candidates.
ACC_SHIFTS = range(8, 19)

# We use a smaller training set first to determine
# the integer training scale.
INTEGER_TRAIN_LIMIT = 10_000

# Candidate integer backpropagation scales.
TRAIN_ACC_SHIFT = 9

TRAIN_SHIFTS = range(15, 23)

def signed_shift_toward_zero(values, shift):
    """
    Divide signed integers by 2**shift,
    truncating symmetrically toward zero.

    This avoids the negative bias of Python's
    arithmetic right shift.
    """

    values = np.asarray(
        values,
        dtype=np.int64,
    )

    magnitude = (
        np.abs(values)
        >> shift
    )

    return np.where(
        values < 0,
        -magnitude,
        magnitude,
    )
# =========================================================
# PLAN activation
# =========================================================

def plan_positive(a):
    """
    Positive side of the PLAN approximation.

    Input:
        non-negative integer

    Output:
        integer approximately 16...32
    """

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


def plan(a):
    """
    FPGA-style PLAN activation.

    Input:
        signed activation value
        saturated to -256...255

    Output:
        0...32
    """

    a = np.asarray(a, dtype=np.int64)

    a = np.clip(
        a,
        -256,
        255,
    )

    abs_a = np.abs(a)

    positive = plan_positive(abs_a)

    # sigmoid(-x) = 1 - sigmoid(x)
    #
    # Because our hardware sigmoid output is scaled
    # from 0...1 to 0...32:
    #
    # PLAN(-x) = 32 - PLAN(x)

    y = np.where(
        a >= 0,
        positive,
        32 - positive,
    )

    return y


# =========================================================
# Load MNIST
# =========================================================

print("Loading MNIST...")

train_dataset = MNIST(
    root=DATA_DIR,
    train=True,
    download=True,
)

test_dataset = MNIST(
    root=DATA_DIR,
    train=False,
    download=True,
)


# ---------------------------------------------------------
# Convert images to NumPy
# ---------------------------------------------------------

train_images_float = (
    train_dataset.data[:INTEGER_TRAIN_LIMIT]
    .numpy()
    .astype(np.float32)
    / 255.0
)

train_labels = (
    train_dataset.targets[:INTEGER_TRAIN_LIMIT]
    .numpy()
)

test_images_float = (
    test_dataset.data[:TEST_LIMIT]
    .numpy()
    .astype(np.float32)
    / 255.0
)

test_labels = (
    test_dataset.targets[:TEST_LIMIT]
    .numpy()
)


# Flatten 28x28 -> 784

train_images_float = train_images_float.reshape(
    -1,
    NUM_INPUTS,
)

test_images_float = test_images_float.reshape(
    -1,
    NUM_INPUTS,
)


# =========================================================
# Quantize pixels
# =========================================================

# MNIST:
#
# float 0.0 ... 1.0
#
# becomes:
#
# integer 0 ... 127

train_images = np.round(
    train_images_float * 127.0
).astype(np.int64)

test_images = np.round(
    test_images_float * 127.0
).astype(np.int64)


print(
    "Training data:",
    train_images.shape,
)

print(
    "Testing data:",
    test_images.shape,
)

print(
    "Integer pixel range:",
    train_images.min(),
    "...",
    train_images.max(),
)


# =========================================================
# Load floating-point trained weights
# =========================================================

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


print()
print("Loaded floating-point weights:")
print(float_weights.shape)

print()
print("Floating-point weight statistics:")

print(
    f"min     = {float_weights.min():.6f}"
)

print(
    f"max     = {float_weights.max():.6f}"
)

max_abs_weight = np.max(
    np.abs(float_weights)
)

print(
    f"max abs = {max_abs_weight:.6f}"
)


# =========================================================
# Quantize trained weights to signed 8-bit
# =========================================================

weight_scale = (
    127.0
    / max_abs_weight
)

int_weights_from_float = np.round(
    float_weights * weight_scale
).astype(np.int64)

int_weights_from_float = np.clip(
    int_weights_from_float,
    -127,
    127,
)


print()
print("8-bit weight quantization:")

print(
    f"scale       = {weight_scale:.6f}"
)

print(
    f"integer min = {int_weights_from_float.min()}"
)

print(
    f"integer max = {int_weights_from_float.max()}"
)


# =========================================================
# Raw integer weighted sums
# =========================================================

# test_images:
#     10000 x 784
#
# weights:
#     10 x 784
#
# accumulator:
#     10000 x 10

accumulators = (
    test_images
    @ int_weights_from_float.T
)


print()
print("Raw accumulator statistics:")

print(
    f"minimum = {accumulators.min()}"
)

print(
    f"maximum = {accumulators.max()}"
)


# =========================================================
# Accuracy before PLAN
# =========================================================

raw_predictions = np.argmax(
    accumulators,
    axis=1,
)

raw_accuracy = np.mean(
    raw_predictions
    == test_labels
)


print()
print(
    "Quantized integer accuracy "
    f"before PLAN: "
    f"{raw_accuracy * 100:.2f}%"
)


# =========================================================
# Find ACC_SHIFT
# =========================================================

print()
print("============================================")
print("ACC_SHIFT sweep")
print("============================================")


acc_results = []

best_acc_accuracy = -1.0
best_acc_shift = None


for shift in ACC_SHIFTS:

    scaled = (
        accumulators
        >> shift
    )


    # Amount of clipping before saturation.

    below_range = np.mean(
        scaled < -256
    )

    above_range = np.mean(
        scaled > 255
    )

    saturation_rate = (
        below_range
        + above_range
    )


    # Saturate to PLAN input range.

    plan_input = np.clip(
        scaled,
        -256,
        255,
    )


    # PLAN activation.

    outputs = plan(
        plan_input
    )


    predictions = np.argmax(
        outputs,
        axis=1,
    )


    accuracy = np.mean(
        predictions
        == test_labels
    )


    # Check how often several classes have
    # exactly the same maximum PLAN output.

    maximum = np.max(
        outputs,
        axis=1,
        keepdims=True,
    )

    tie_count = np.sum(
        outputs == maximum,
        axis=1,
    )

    tie_rate = np.mean(
        tie_count > 1
    )


    print(
        f"shift={shift:2d} | "
        f"accuracy={accuracy * 100:6.2f}% | "
        f"saturation={saturation_rate * 100:6.2f}% | "
        f"ties={tie_rate * 100:6.2f}%"
    )


    acc_results.append(
        (
            shift,
            accuracy,
            saturation_rate,
            tie_rate,
        )
    )


    if accuracy > best_acc_accuracy:

        best_acc_accuracy = accuracy
        best_acc_shift = shift


# =========================================================
# Selected ACC_SHIFT
# =========================================================

print()
print("============================================")
print("Best fixed-point forward configuration")
print("============================================")

print(
    f"ACC_SHIFT = {best_acc_shift}"
)

print(
    f"Accuracy  = {best_acc_accuracy * 100:.2f}%"
)


# =========================================================
# Save fixed-forward results
# =========================================================

np.save(
    WEIGHTS_DIR
    / "int8_weights_from_float.npy",
    int_weights_from_float,
)


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


# =========================================================
# FPGA-style integer forward function
# =========================================================

def integer_forward(
    weights,
    image,
    acc_shift,
):
    """
    Forward propagation matching the intended RTL.

    weights:
        10 x 784 signed integer weights

    image:
        784 integer pixels

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


# =========================================================
# Vectorized integer evaluation
# =========================================================

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


# =========================================================
# Integer FPGA-style training
# =========================================================

print()
print("============================================")
print("Integer training TRAIN_SHIFT sweep")
print("============================================")


rng = np.random.default_rng(
    SEED
)


# The paper says weights are initialized randomly.
#
# We use small signed integer values so the initial
# weighted sums do not immediately saturate.

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

initial_weights = np.clip(
    initial_weights,
    -128,
    127,
)

print(
    "Initial integer weight range:",
    initial_weights.min(),
    "...",
    initial_weights.max(),
)


train_results = []

best_train_accuracy = -1.0
best_train_shift = None
best_train_weights = None


for train_shift in TRAIN_SHIFTS:

    print()
    print(
        f"Training with TRAIN_SHIFT="
        f"{train_shift}"
    )


    # Every experiment starts from exactly
    # the same initial weights.

    weights = (
        initial_weights.copy()
    )


    # -----------------------------------------------------
    # Online training
    # -----------------------------------------------------

    for sample_index in range(
        INTEGER_TRAIN_LIMIT
    ):

        image = (
            train_images[sample_index]
        )

        label = (
            train_labels[sample_index]
        )


        # ---------------------------------------------
        # Forward propagation
        # ---------------------------------------------

        prediction, outputs = (
            integer_forward(
                weights,
                image,
                TRAIN_ACC_SHIFT,
            )
        )


        # ---------------------------------------------
        # Target
        #
        # correct neuron   = 32
        # incorrect neuron = 0
        # ---------------------------------------------

        target = np.zeros(
            NUM_OUTPUTS,
            dtype=np.int64,
        )

        target[label] = 32


        # ---------------------------------------------
        # Error
        #
        # error_i = target_i - y_i
        # ---------------------------------------------

        error = (
            target
            - outputs
        )


        # ---------------------------------------------
        # Sigmoid gradient
        #
        # y_real = Y / 32
        #
        # therefore the numerator of
        #
        # y(1-y)
        #
        # is:
        #
        # Y * (32-Y)
        # ---------------------------------------------

        gradient = (
            outputs
            * (32 - outputs)
        )


        # ---------------------------------------------
        # Neuron correction
        # ---------------------------------------------

        correction = (
            error
            * gradient
        )


                # ---------------------------------------------
        # Weight update
        #
        # delta_w =
        #
        # pixel
        # *
        # error
        # *
        # sigmoid_gradient
        # ---------------------------------------------

        delta_weights = np.outer(
            correction,
            image,
        )

        # Fixed-point / learning-rate scaling.
        #
        # Use symmetric truncation toward zero
        # instead of Python's arithmetic right shift.

        delta_weights = signed_shift_toward_zero(
            delta_weights,
            train_shift,
        )


        weights += (
            delta_weights
        )

    # -----------------------------------------------------
    # Evaluate this training configuration
    # -----------------------------------------------------

    accuracy = evaluate_integer(
        weights,
        test_images,
        test_labels,
        TRAIN_ACC_SHIFT,
    )


    saturated_weights = np.mean(
        (weights == -128)
        |
        (weights == 127)
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
            zero_weights,
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


# =========================================================
# Final integer-training result
# =========================================================

print()
print("============================================")
print("Best integer-training configuration")
print("============================================")

print(
    f"TRAIN_SHIFT = {best_train_shift}"
)

print(
    f"Accuracy    = "
    f"{best_train_accuracy * 100:.2f}%"
)


# =========================================================
# Save integer training results
# =========================================================

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


# =========================================================
# Save final fixed-point parameters
# =========================================================

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