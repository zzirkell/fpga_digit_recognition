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
TRAIN_LIMIT = 55_000
TEST_LIMIT = 10_000
LEARNING_RATE = 1.0 #how much updated weight to summ

CHECKPOINTS = [
    1_000,
    5_000,
    10_000,
    20_000,
    40_000,
    55_000,
]

#standard sigmoid activation.
def sigmoid(x):
    #prevent extremely large values (exp overflow).
    x = np.clip(x, -50.0, 50.0)
    return 1.0 / (1.0 + np.exp(-x))

#target vector
def one_hot(label): #ex:6 -> [0,0,0,0,0,0,1,0,0,0]
    target = np.zeros(
        NUM_OUTPUTS,
        dtype=np.float32
    )
    target[label] = 1.0
    return target

#predict one image
def predict(weights, image):
    """
    weights:[10, 784]
    image:[784]
    prediction = digit 0...9
    outputs: [10]
    """
    #matrix multiplication
    weighted_sum = (
        weights @ image
    )

    #apply sigmoid to each of 10
    outputs = sigmoid(weighted_sum)
    #find which neuron has the largest output
    prediction = int(
        np.argmax(outputs)
    )
    return prediction, outputs

#evaluate many images (accuracy)
def evaluate(weights, images, labels):
    weighted_sum = (
        weights @ images.T #dont forget to transpose
    )
    outputs = sigmoid(weighted_sum)

    #for every image, find which neuron has the largest output
    predictions = np.argmax(
        outputs,
        axis=0
    )

    #taking the mean gives accuracy.
    accuracy = np.mean(predictions == labels)
    return accuracy


#2 mnist datasets: training and testing
print("Loading MNIST...")
train_dataset = MNIST(
    root=DATA_DIR,
    train=True,
    download=True
)
test_dataset = MNIST(
    root=DATA_DIR,
    train=False,
    download=True
)

#MNIST (grayscale intensity) ->  NumPy (/255)
train_images = (train_dataset.data[:TRAIN_LIMIT].numpy().astype(np.float32) / 255.0)
train_labels = (train_dataset.targets[:TRAIN_LIMIT].numpy())
test_images = (test_dataset.data[:TEST_LIMIT].numpy().astype(np.float32) / 255.0)
test_labels = (test_dataset.targets[:TEST_LIMIT].numpy())


#flatten to vectors (55000, 784)
train_images = train_images.reshape(-1,NUM_INPUTS)
test_images = test_images.reshape(-1,NUM_INPUTS)

print("Training data:", train_images.shape)
print("Testing data: ", test_images.shape)

#init weights with random numbers between -0.05 and 0.05
rng = np.random.default_rng(SEED)
weights = rng.uniform(
    low=-0.05,
    high=0.05,
    size=(
        NUM_OUTPUTS,
        NUM_INPUTS,
    ),
).astype(np.float32)

#online training
print()
print("Starting online training...")
print()
accuracy_history = []

for sample_index in range(TRAIN_LIMIT):
    #get one training image
    image = (train_images[sample_index])
    label = (train_labels[sample_index])

    #forward pass (prediction) !!!base
    weighted_sum = (
        weights @ image
    )
    outputs = sigmoid(
        weighted_sum
    )
    target = one_hot(
        label
    )

    #backpropagation (weight update)
    error = target - outputs

    #gradient of sigmoid: y * (1-y) -> *error correction value for each neuron
    neuron_change = (
        error
        * outputs
        * (1.0 - outputs)
    )

    #change weights with outer product (10, 784)
    weight_change = np.outer(neuron_change,  image)

    #no weight update in our example
    weights += LEARNING_RATE * weight_change

    #evaluation section
    trained_images = sample_index + 1
    if trained_images in CHECKPOINTS:
        accuracy = evaluate(
            weights,
            test_images,
            test_labels
        )
        accuracy_history.append((trained_images, accuracy))
        print(
            f"After {trained_images:5d} "
            f"training images: "
            f"test accuracy = "
            f"{accuracy * 100:.2f}%"
        )

        #save weights to file for later
        checkpoint_file = (WEIGHTS_DIR / f"float_weights_{trained_images}.npy")
        np.save(checkpoint_file, weights)


#final test
print("now trained model")
final_accuracy = evaluate(
    weights,
    test_images,
    test_labels
)
print(f"Accuracy: {final_accuracy * 100:.2f}%")
print("Example predictions:")
print()

for i in range(10):
    prediction, outputs = predict(weights, test_images[i])
    print(
        f"Image {i:2d}: "
        f"label={test_labels[i]} "
        f"prediction={prediction}"
    )

#save weights to file for later
weights_file = (WEIGHTS_DIR / "float_weights.npy")
np.save(weights_file, weights)
print("Saved weights to:")
print(weights_file)

#accuracy history to file for later
history_file = (RESULTS_DIR / "float_accuracy_history.csv")
np.savetxt(
    history_file,
    np.array(accuracy_history),
    delimiter=",",
    header=(
        "training_images,"
        "accuracy"
    ),
    comments=""
)
print("Saved accuracy history to:")
print(history_file)