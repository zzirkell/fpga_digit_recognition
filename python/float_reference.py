import numpy as np
from pathlib import Path

from torchvision.datasets import MNIST


# ---------------------------------------------------------
# Project paths
# ---------------------------------------------------------

PROJECT_DIR = Path(__file__).resolve().parent.parent

WEIGHTS_DIR = PROJECT_DIR / "weights"
RESULTS_DIR = PROJECT_DIR / "results"
DATA_DIR = PROJECT_DIR / "data"


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

NUM_INPUTS = 784
NUM_OUTPUTS = 10

TEST_LIMIT = 10_000

# We will test several accumulator scaling choices.
ACC_SHIFTS = range(8, 19)


# ---------------------------------------------------------
# PLAN activation
# ---------------------------------------------------------

def plan_positive(a):
    """
    PLAN approximation for non-negative integer input.

    Paper:
        y = 32                    , a >= 160
        y = a/32 + 27            , 76 <= a < 160
        y = a/8  + 20            , 32 <= a < 76
        y = a/4  + 16            , 0 <= a < 32

    Division by powers of two is implemented as shifts.
    """

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
    """
    Integer PLAN.

    Input:
        signed 9-bit conceptual range:
        -256 ... +255

    Output:
        0 ... 32
    """

    a = np.asarray(a, dtype=np.int64)

    # Saturate to the 9-bit activation-input range.
    a = np.clip(a, -256, 255)

    abs_a = np.abs(a)

    positive_result = plan_positive(abs_a)

    # sigmoid(-x) = 1 - sigmoid(x)
    #
    # Our sigmoid output is scaled from [0,1]
    # to [0,32], therefore:
    #
    # PLAN(-x) = 32 - PLAN(x)
    y = np.where(
        a >= 0,
        positive_result,
        32 - positive_result,
    )

    return y


# ---------------------------------------------------------
# Load floating-point trained weights
# ---------------------------------------------------------

weights_file = WEIGHTS_DIR / "float_weights.npy"

float_weights = np.load(weights_file)

print("Loaded floating-point weights:")
print(float_weights.shape)

print()
print("Weight statistics:")
print(f"min      = {float_weights.min():.6f}")
print(f"max      = {float_weights.max():.6f}")
print(f"max abs  = {np.max(np.abs(float_weights)):.6f}")


# ---------------------------------------------------------
# Quantize weights to signed 8-bit
# ---------------------------------------------------------

max_abs_weight = np.max(np.abs(float_weights))

weight_scale = 127.0 / max_abs_weight

int_weights = np.round(
    float_weights * weight_scale
).astype(np.int64)

int_weights = np.clip(
    int_weights,
    -127,
    127,
)

print()
print("8-bit weight quantization:")
print(f"scale       = {weight_scale:.6f}")
print(f"integer min = {int_weights.min()}")
print(f"integer max = {int_weights.max()}")


# ---------------------------------------------------------
# Load MNIST test images
# ---------------------------------------------------------

test_dataset = MNIST(
    root=DATA_DIR,
    train=False,
    download=True,
)

test_images = (
    test_dataset.data[:TEST_LIMIT]
    .numpy()
    .astype(np.float32)
    / 255.0
)

test_labels = (
    test_dataset.targets[:TEST_LIMIT]
    .numpy()
)

test_images = test_images.reshape(
    -1,
    NUM_INPUTS,
)


# ---------------------------------------------------------
# Quantize pixels
# ---------------------------------------------------------

# 0.0 ... 1.0
#       ↓
# 0 ... 127
#
# Keeping pixels in signed-8-bit positive range makes
# the eventual Verilog multiplier straightforward.

int_images = np.round(
    test_images * 127.0
).astype(np.int64)


print()
print("Pixel range:")
print(
    int_images.min(),
    "...",
    int_images.max(),
)


# ---------------------------------------------------------
# Integer weighted sums
# ---------------------------------------------------------

# Shape:
#
# images:   10000 x 784
# weights:     10 x 784
#
# result:   10000 x 10

accumulators = (
    int_images
    @ int_weights.T
)


print()
print("Raw accumulator statistics:")
print(f"minimum = {accumulators.min()}")
print(f"maximum = {accumulators.max()}")


# ---------------------------------------------------------
# Useful baseline:
# prediction before PLAN
# ---------------------------------------------------------

raw_predictions = np.argmax(
    accumulators,
    axis=1,
)

raw_accuracy = np.mean(
    raw_predictions == test_labels
)

print()
print(
    "Quantized integer accuracy "
    f"before PLAN: {raw_accuracy * 100:.2f}%"
)


# ---------------------------------------------------------
# Sweep accumulator shifts
# ---------------------------------------------------------

print()
print("--------------------------------------------")
print("ACC_SHIFT sweep")
print("--------------------------------------------")

best_accuracy = -1.0
best_shift = None

results = []

for shift in ACC_SHIFTS:

    scaled = accumulators >> shift

    # Diagnostics before saturation.
    below_range = np.mean(
        scaled < -256
    )

    above_range = np.mean(
        scaled > 255
    )

    plan_input = np.clip(
        scaled,
        -256,
        255,
    )

    outputs = plan(plan_input)

    predictions = np.argmax(
        outputs,
        axis=1,
    )

    accuracy = np.mean(
        predictions == test_labels
    )

    # Count images where multiple classes share
    # the maximum PLAN result.
    max_values = np.max(
        outputs,
        axis=1,
        keepdims=True,
    )

    ties = np.sum(
        outputs == max_values,
        axis=1,
    )

    tie_rate = np.mean(
        ties > 1
    )

    saturation_rate = (
        below_range + above_range
    )

    results.append(
        (
            shift,
            accuracy,
            saturation_rate,
            tie_rate,
        )
    )

    print(
        f"shift={shift:2d} | "
        f"accuracy={accuracy * 100:6.2f}% | "
        f"saturation={saturation_rate * 100:6.2f}% | "
        f"ties={tie_rate * 100:6.2f}%"
    )

    if accuracy > best_accuracy:
        best_accuracy = accuracy
        best_shift = shift


# ---------------------------------------------------------
# Best result
# ---------------------------------------------------------

print()
print("--------------------------------------------")
print("Best fixed-point forward configuration")
print("--------------------------------------------")

print(f"ACC_SHIFT = {best_shift}")
print(
    f"Accuracy  = {best_accuracy * 100:.2f}%"
)


# ---------------------------------------------------------
# Save sweep results
# ---------------------------------------------------------

results_file = (
    RESULTS_DIR
    / "fixed_forward_shift_sweep.csv"
)

np.savetxt(
    results_file,
    np.array(results),
    delimiter=",",
    header=(
        "acc_shift,"
        "accuracy,"
        "saturation_rate,"
        "tie_rate"
    ),
    comments="",
)

print()
print("Saved results to:")
print(results_file)