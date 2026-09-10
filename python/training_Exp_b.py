import numpy as np
from pathlib import Path
from torchvision.datasets import MNIST

PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data"
WEIGHTS_DIR = PROJECT_DIR / "weights"
MEM_DIR = PROJECT_DIR / "rtl" / "mem"
MEM_DIR.mkdir(parents=True, exist_ok=True)

NUM_IMAGES = 10000
NUM_PIXELS = 784
NUM_OUTPUTS = 10
SEED = 42

#load first 10kimages

train_dataset = MNIST(root=DATA_DIR, train=True, download=True)

images_float = train_dataset.data[:NUM_IMAGES].numpy().astype(np.float32) / 255.0
images = np.round(images_float.reshape(NUM_IMAGES, NUM_PIXELS) * 127.0).astype(np.int64)
labels = train_dataset.targets[:NUM_IMAGES].numpy().astype(np.int64)

#gen init

rng = np.random.default_rng(SEED)
initial_float_weights = rng.uniform(-0.05, 0.05, size=(NUM_OUTPUTS, NUM_PIXELS))
initial_weights = np.round(initial_float_weights * 128.0).astype(np.int64)
initial_weights = np.clip(initial_weights, -128, 127)

#load exp weights after 10k
expected_weights = np.load(WEIGHTS_DIR / "integer_trained_weights_10000.npy").astype(np.int64)

print("Training images:", images.shape)
print("Initial weights:", initial_weights.shape)
print("Expected final weights:", expected_weights.shape)

#large img steram

with open(MEM_DIR / "expB_train_images_10000.mem", "w") as f:
    for image in images:
        for pixel in image:
            f.write(f"{int(pixel) & 0xFF:02X}\n")

#labels

with open(MEM_DIR / "expB_train_labels_10000.mem", "w") as f:
    for label in labels:
        f.write(f"{int(label):X}\n")

#init vs exp

for neuron in range(NUM_OUTPUTS):
    with open(MEM_DIR / f"expB_train_initial_{neuron}.mem", "w") as f:
        for weight in initial_weights[neuron]:
            f.write(f"{int(weight) & 0xFF:02X}\n")

    with open(MEM_DIR / f"expB_train_final_expected_{neuron}.mem", "w") as f:
        for weight in expected_weights[neuron]:
            f.write(f"{int(weight) & 0xFF:02X}\n")

print()
print("Export complete.")