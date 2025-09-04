import os
import cv2
import numpy as np
import tensorflow as tf
from keras import activations
from keras.saving import register_keras_serializable
from tensorflow.keras.applications.inception_v3 import preprocess_input

# --- Patch for 'softmax_v2' (legacy compatibility) ---
@register_keras_serializable()
def softmax_v2(x, axis=-1):
    return activations.softmax(x, axis=axis)

# Path to your trained InceptionV3 model
MODEL_PATH = os.path.join(os.path.dirname(__file__), "model_inceptionv3.h5")

print(f"[ML] Loading InceptionV3 model from {MODEL_PATH} ...")
model = tf.keras.models.load_model(MODEL_PATH)
print("[ML] Model loaded ✅")

# Image size used in training
IMG_SIZE = 224

# Classes (must match your dataset folder names inside archive/train)
CLASSES = sorted([
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___healthy",
])


def prepare_image(filepath):
    """Load and preprocess an image for InceptionV3 prediction."""
    img = cv2.imread(filepath, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Could not load image: {filepath}")
    
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img = img.astype(np.float32)
    img = np.expand_dims(img, axis=0)  # (1, 224, 224, 3)
    img = preprocess_input(img)  # InceptionV3 preprocessing
    return img


def predict_image(filepath):
    """Run prediction on a single image file."""
    img = prepare_image(filepath)
    preds = model.predict(img)
    class_idx = int(np.argmax(preds))
    confidence = float(np.max(preds))
    return {
        "disease": CLASSES[class_idx],
        "confidence": confidence
    }
