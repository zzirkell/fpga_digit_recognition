import numpy as np
from pathlib import Path
from torchvision.datasets import MNIST

#paths
PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data"
WEIGHTS_DIR = PROJECT_DIR / "weights"
MEM_DIR = PROJECT_DIR / "rtl" / "mem"
MEM_DIR.mkdir(parents=True, exist_ok=True)

#configuration
NUM_INPUTS = 784
NUM_OUTPUTS = 10
TEST_LIMIT = 10_000
ACC_SHIFT = 11

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


# Load Experiment-B weights
weights_file = WEIGHTS_DIR / "integer_trained_weights_10000.npy"

if not weights_file.exists():
    raise FileNotFoundError("integer_trained_weights_10000.npy was not found.")

weights = np.load(weights_file).astype(np.int64)
print("Weights shape:", weights.shape)


#Load complete MNIST test set
test_dataset = MNIST(root=DATA_DIR, train=False, download=True)

test_images_float = test_dataset.data[:TEST_LIMIT].numpy().astype(np.float32) / 255.0
test_labels = test_dataset.targets[:TEST_LIMIT].numpy().astype(np.int64)
test_images_float = test_images_float.reshape(TEST_LIMIT, NUM_INPUTS)

#same integer pixel representation used by Experiment B
test_images = np.round(test_images_float * 127.0).astype(np.int64)

print("Test images:", test_images.shape)
print("Pixel range:", test_images.min(), "...", test_images.max())


#python integer forward pass over all 10,000 images
accumulators = test_images @ weights.T
plan_inputs = accumulators >> ACC_SHIFT
plan_inputs = np.clip(plan_inputs, -256, 255)
activations = plan(plan_inputs)
predictions = np.argmax(activations, axis=1)
accuracy = np.mean(predictions == test_labels)

print()
print("EXPERIMENT B PYTHON REFERENCE")
print(f"ACC_SHIFT = {ACC_SHIFT}")
print(f"Accuracy  = {accuracy * 100:.2f}%")
print(f"Correct   = {np.sum(predictions == test_labels)} / {TEST_LIMIT}")


#exp10000 images, labels, and expected predictions for RTL simulation

images_file = MEM_DIR / "expB_test_images_10000.mem"

with open(images_file, "w") as f:
    for image in test_images:
        for pixel in image:
            f.write(f"{int(pixel) & 0xFF:02X}\n")


#labels
labels_file = MEM_DIR / "expB_test_labels_10000.mem"

with open(labels_file, "w") as f:
    for label in test_labels:
        f.write(f"{int(label):X}\n")


#expected Python predictions
predictions_file = MEM_DIR / "expB_python_predictions_10000.mem"

with open(predictions_file, "w") as f:
    for prediction in predictions:
        f.write(f"{int(prediction):X}\n")


print()
print("Exported:")
print(images_file)
print(labels_file)
print(predictions_file)