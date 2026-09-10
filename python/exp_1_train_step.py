import numpy as np
from pathlib import Path
from torchvision.datasets import MNIST

#configs
PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data"
MEM_DIR = PROJECT_DIR / "rtl" / "mem"
MEM_DIR.mkdir(parents=True, exist_ok=True)

SEED = 42
NUM_INPUTS = 784
NUM_OUTPUTS = 10
ACC_SHIFT = 11
TRAIN_SHIFT = 18
SAMPLE_INDEX = 0

#plan
def plan_positive(a):
    a = np.asarray(a, dtype=np.int64)
    y = np.zeros_like(a)

    mask = a >= 160
    y[mask] = 32

    mask = (a >= 76) & (a < 160)
    y[mask] = (a[mask] >> 5) + 27

    mask = (a >= 32) & (a < 76)
    y[mask] = (a[mask] >> 3) + 20

    mask = (a >= 0) & (a < 32)
    y[mask] = (a[mask] >> 2) + 16

    return y

def plan(a):
    a = np.asarray(a, dtype=np.int64)
    a = np.clip(a, -256, 255)
    positive = plan_positive(np.abs(a))
    return np.where(a >= 0, positive, 32 - positive)

def signed_shift_toward_zero(values, shift):
    values = np.asarray(values, dtype=np.int64)
    magnitude = np.abs(values) >> shift
    return np.where(values < 0, -magnitude, magnitude)
#8init weights

rng = np.random.default_rng(SEED)

initial_float_weights = rng.uniform(
    low=-0.05,
    high=0.05,
    size=(NUM_OUTPUTS, NUM_INPUTS),
)

initial_weights = np.round(
    initial_float_weights * 128.0
).astype(np.int64)

initial_weights = np.clip(initial_weights, -128, 127)

print("Initial weight range:", initial_weights.min(), "...", initial_weights.max())

#1st train image
train_dataset = MNIST(root=DATA_DIR, train=True, download=True)

image_float = (
    train_dataset.data[SAMPLE_INDEX]
    .numpy()
    .astype(np.float32)
    / 255.0
)

image = np.round(
    image_float.reshape(NUM_INPUTS) * 127.0
).astype(np.int64)

label = int(train_dataset.targets[SAMPLE_INDEX])

#forward prop
accumulators = initial_weights @ image
plan_inputs = accumulators >> ACC_SHIFT
plan_inputs = np.clip(plan_inputs, -256, 255)
outputs = plan(plan_inputs)
prediction = int(np.argmax(outputs))

#backprop
target = np.zeros(NUM_OUTPUTS, dtype=np.int64)
target[label] = 32

error = target - outputs
gradient = outputs * (32 - outputs)
correction = error * gradient

#weight update
raw_delta = np.outer(correction, image)

delta_weights = signed_shift_toward_zero(
    raw_delta,
    TRAIN_SHIFT,
)

expected_weights = initial_weights + delta_weights

#match
expected_weights = np.clip(
    expected_weights,
    -128,
    127,
)

print()
print("ONE TRAINING IMAGE - PYTHON REFERENCE")
print("Sample index:", SAMPLE_INDEX)
print("True label:", label)
print("Prediction before update:", prediction)
print()
print("Accumulators:")
print(accumulators)
print()
print("PLAN inputs:")
print(plan_inputs)
print()
print("PLAN outputs:")
print(outputs)
print()
print("Targets:")
print(target)
print()
print("Errors:")
print(error)
print()
print("Gradients:")
print(gradient)
print()
print("Corrections:")
print(correction)

changed = np.sum(expected_weights != initial_weights)

print()
print("Weights changed:", changed, "/", NUM_OUTPUTS * NUM_INPUTS)
print("Initial weight range:", initial_weights.min(), "...", initial_weights.max())
print("Updated weight range:", expected_weights.min(), "...", expected_weights.max())

#helper function to write byte memory files for RTL simulation

def write_byte_memory(path, values):
    with open(path, "w") as f:
        for value in values:
            f.write(f"{int(value) & 0xFF:02X}\n")

#exp
write_byte_memory(
    MEM_DIR / "train_image_0.mem",
    image,
)

for neuron in range(NUM_OUTPUTS):
    write_byte_memory(
        MEM_DIR / f"train_initial_weights_{neuron}.mem",
        initial_weights[neuron],
    )

    write_byte_memory(
        MEM_DIR / f"train_expected_weights_{neuron}.mem",
        expected_weights[neuron],
    )

#for human readability and comparison 

with open(MEM_DIR / "train_step_expected.txt", "w") as f:
    f.write(f"sample_index={SAMPLE_INDEX}\n")
    f.write(f"label={label}\n")
    f.write(f"prediction_before_update={prediction}\n")
    f.write(
        "outputs="
        + " ".join(str(int(x)) for x in outputs)
        + "\n"
    )
    f.write(
        "corrections="
        + " ".join(str(int(x)) for x in correction)
        + "\n"
    )
    f.write(f"weights_changed={changed}\n")

print()
print("Exported files to:", MEM_DIR)