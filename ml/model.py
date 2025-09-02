import os

import cv2
import numpy as np
import tensorflow as tf
from keras import activations
from keras.saving import register_keras_serializable


# --- Patch for 'softmax_v2' ---
@register_keras_serializable()
def softmax_v2(x, axis=-1):
    return activations.softmax(x, axis=axis)


MODEL_PATH = os.path.join(os.path.dirname(__file__), "64x3-tomato_leaves.h5")

print(f"[ML] Loading model from {MODEL_PATH} ...")
model = tf.keras.models.load_model(MODEL_PATH)
print("[ML] Model loaded ✅")

# Hardcode your classes since training folder isn’t available now
CLASSES = [
    "Tomato_Bacterial_spot",
    "Tomato_Early_blight",
    "Tomato_Late_blight",
    "Tomato_Leaf_Mold",
    "Tomato_Septoria_leaf_spot",
    "Tomato_Yellow_Leaf_Curl_Virus",
]


def prepare_image(filepath):
    img = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
    img = cv2.resize(img, (70, 70))
    img = img.reshape(-1, 70, 70, 1) / 255.0
    return img


def predict_image(filepath):
    img = prepare_image(filepath)
    preds = model.predict(img)
    class_idx = int(np.argmax(preds))
    confidence = float(np.max(preds))
    return {"disease": CLASSES[class_idx], "confidence": confidence}
