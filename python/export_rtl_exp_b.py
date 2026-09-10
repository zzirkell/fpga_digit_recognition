import numpy as np
from pathlib import Path
from torchvision.datasets import MNIST

PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data"
WEIGHTS_DIR = PROJECT_DIR / "weights"
MEM_DIR = PROJECT_DIR / "rtl" / "mem"
MEM_DIR.mkdir(parents=True, exist_ok=True)
#exp b configs
NUM_INPUTS = 784
NUM_OUTPUTS = 10
ACC_SHIFT = 11
SAMPLE_INDEX = 0

#PLAN
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
    abs_a = np.abs(a)
    positive = plan_positive(abs_a)
    return np.where(a >= 0, positive, 32 - positive)


#load quantized Experiment-A weights
weights_file = (
    WEIGHTS_DIR
    / "integer_trained_weights_10000.npy"
)
if not weights_file.exists():
    raise FileNotFoundError(
        "integer_trained_weights_10000.npy not found. "
        "Run integer training first."
    )

weights = np.load(
    weights_file
).astype(np.int64)
print("Weights shape:", weights.shape)


#load one real MNIST test image
test_dataset = MNIST(root=DATA_DIR, train=False, download=True)

image_float = test_dataset.data[SAMPLE_INDEX].numpy().astype(np.float32) / 255.0
label = int(test_dataset.targets[SAMPLE_INDEX])
image_float = image_float.reshape(NUM_INPUTS)

#same pixel quantization used in Experiment A
image = np.round(image_float * 127.0).astype(np.int64)

print()
print("Sample index:", SAMPLE_INDEX)
print("True label:", label)
print("Pixel range:", image.min(), "...", image.max())


#pyth Experiment-A forward pass
accumulators = weights @ image
plan_input = accumulators >> ACC_SHIFT
plan_input = np.clip(plan_input, -256, 255)
activations = plan(plan_input)
prediction = int(np.argmax(activations))

print()
print("PYTHON EXPECTED RTL VALUES")
print("ACC_SHIFT:", ACC_SHIFT)
print("Accumulators:")
print(accumulators)
print("PLAN inputs:")
print(plan_input)
print("PLAN activations:")
print(activations)
print("True label:", label)
print("Prediction:", prediction)


#export image memory and 10 weight memories for RTL simulation
image_file = MEM_DIR / "expB_image_0.mem"

with open(image_file, "w") as f:
    for value in image:
        # 8-bit unsigned pixel
        f.write(f"{int(value) & 0xFF:02X}\n")


#10 weight memories
for neuron in range(NUM_OUTPUTS):
    weight_file = MEM_DIR / f"expB_weights_{neuron}.mem"

    with open(weight_file, "w") as f:
        for value in weights[neuron]:
            # Convert signed integer to raw 8-bit two's-complement representation
            raw_byte = int(value) & 0xFF
            f.write(f"{raw_byte:02X}\n")


#human readable expected values for RTL simulation
expected_file = MEM_DIR / "expB_expected.txt"

with open(expected_file, "w") as f:
    f.write(f"sample_index={SAMPLE_INDEX}\n")
    f.write(f"label={label}\n")
    f.write(f"acc_shift={ACC_SHIFT}\n")
    f.write("accumulators=" + " ".join(str(int(x)) for x in accumulators) + "\n")
    f.write("plan_inputs=" + " ".join(str(int(x)) for x in plan_input) + "\n")
    f.write("activations=" + " ".join(str(int(x)) for x in activations) + "\n")
    f.write(f"prediction={prediction}\n")

print()
print("Exported RTL memory files to:")
print(MEM_DIR)
