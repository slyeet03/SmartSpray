"""
File: app.py
Flask server for SmartSpray.
Handles ML predictions, spray scheduling, ESP32 communication,
and app API for logs + manual control + webcam capture.
"""

import os
import cv2
import numpy as np
import requests
from flask import Flask, request, jsonify

from ml.model import predict_image
from server.schedule import get_recommendation
from server.logger import save_log, load_logs

# Flask app
app = Flask(__name__)

# ⚡ CHANGE THIS to match the ESP32's IP from Serial Monitor
ESP32_URL = "http://10.230.158.86"  

# ───────────────────────────────
# ROUTES
# ───────────────────────────────

@app.route("/")
def index():
    return jsonify({"message": "SmartSpray server running "})


@app.route("/detect", methods=["POST"])
def detect():
    """Handle plant image upload from Flutter app."""
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files["image"]
    npimg = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

    return process_and_act(frame, source="Upload")


@app.route("/capture", methods=["GET"])
def capture():
    """Capture image from laptop webcam and run ML."""
    cap = cv2.VideoCapture(0)  # 0 = default webcam
    if not cap.isOpened():
        return jsonify({"error": "Webcam not accessible"}), 500

    ret, frame = cap.read()
    cap.release()

    if not ret:
        return jsonify({"error": "Failed to capture frame"}), 500

    return process_and_act(frame, source="Webcam")


@app.route("/override", methods=["POST"])
def override():
    """Manual override from Flutter app."""
    data = request.get_json(force=True)
    spray = data.get("spray", False)
    spray_time = data.get("spray_time", 0)
    servo_index = data.get("servo_index", 0)
    chemical = data.get("chemical", "Manual Chemical")

    log_entry = {
        "disease": "Manual Override",
        "confidence": 1.0,
        "spray": spray,
        "spray_time": spray_time,
        "servo_index": servo_index,
        "chemical": chemical
    }

    if spray:
        log_entry["esp32_response"] = send_to_esp32(spray_time, servo_index)

    save_log(log_entry)
    return jsonify({"status": "Override applied", "log": log_entry})


@app.route("/logs", methods=["GET"])
def logs():
    """Return detection & spray logs."""
    logs = load_logs()
    last = request.args.get("last")
    if last:
        try:
            n = int(last)
            logs = logs[-n:]
        except ValueError:
            pass
    return jsonify(logs)

# ───────────────────────────────
# HELPERS
# ───────────────────────────────

def process_and_act(frame, source="Unknown"):
    """Run ML prediction, log result, send command to ESP32 if needed."""
    # Save captured image to data/ folder with timestamp
    from datetime import datetime
    data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
    os.makedirs(data_dir, exist_ok=True)

    filename = f"capture_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
    img_path = os.path.join(data_dir, filename)
    cv2.imwrite(img_path, frame)


    # Predict disease
    result = predict_image(img_path)  # {"disease": "...", "confidence": ...}
    recommendation = get_recommendation(result["disease"])

    # Create log entry
    log_entry = {
        "source": source,
        "disease": recommendation["disease"],
        "confidence": result["confidence"],
        "spray": recommendation["spray"],
        "spray_time": recommendation["spray_time"],
        "servo_index": recommendation["servo_index"],
        "chemical": recommendation["chemical"]
    }

    if recommendation["spray"]:
        log_entry["esp32_response"] = send_to_esp32(
            recommendation["spray_time"], recommendation["servo_index"]
        )

    save_log(log_entry)

    return jsonify({"prediction": result, "recommendation": recommendation, "log": log_entry})


def send_to_esp32(duration, servo_index):
    """Send spray command to ESP32."""
    try:
        r = requests.get(
            f"{ESP32_URL}/servo",
            params={"duration": duration, "servoindex": servo_index},
            timeout=5
        )
        return r.text
    except Exception as e:
        return f"Error: {str(e)}"

# ───────────────────────────────
# MAIN
# ───────────────────────────────

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=True)
