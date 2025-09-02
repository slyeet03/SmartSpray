"""
File: app.py
Flask server for SmartSpray.
Handles ML predictions, spray scheduling, ESP32 communication,
and app API for logs + manual control.
"""

import os

import cv2
import numpy as np
from flask import Flask, jsonify, request

from ml.model import predict_image
from server.logger import load_logs, save_log
from server.schedule import get_recommendation

# Flask app
app = Flask(__name__)

# Global state for ESP32
current_command = {
    "spray": False,
    "spray_time": 0,
    "servo_index": None,
    "chemical": None,
}

# ───────────────────────────────
# ROUTES
# ───────────────────────────────


@app.route("/")
def index():
    return jsonify({"message": "SmartSpray server running ✅"})


@app.route("/detect", methods=["POST"])
def detect():
    """Handle plant image upload, run ML, return recommendation."""
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files["image"]
    npimg = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

    # Run ML model
    result = predict_image(frame)  # {"class_id": "...", "confidence": ...}
    recommendation = get_recommendation(result["class_id"])

    # Create log entry
    log_entry = {
        "class_id": result["class_id"],
        "disease": recommendation["disease"],
        "confidence": result["confidence"],
        "spray": recommendation["spray"],
        "spray_time": recommendation["spray_time"],
        "servo_index": recommendation["servo_index"],
        "chemical": recommendation["chemical"],
    }
    save_log(log_entry)

    # Update global command for ESP32
    global current_command
    current_command = {
        "spray": recommendation["spray"],
        "spray_time": recommendation["spray_time"],
        "servo_index": recommendation["servo_index"],
        "chemical": recommendation["chemical"],
    }

    return jsonify({"prediction": result, "recommendation": recommendation})


@app.route("/command", methods=["GET"])
def command():
    """ESP32 polls this to get the latest spray command."""
    return jsonify(current_command)


@app.route("/override", methods=["POST"])
def override():
    """Manual override from Flutter app."""
    data = request.get_json(force=True)
    global current_command
    current_command = {
        "spray": data.get("spray", False),
        "spray_time": data.get("spray_time", 0),
        "servo_index": data.get("servo_index", None),
        "chemical": data.get("chemical", None),
    }

    # Log the manual action
    save_log(
        {
            "class_id": "Manual Override",
            "disease": "Manual Override",
            "confidence": 1.0,
            **current_command,
        }
    )

    return jsonify({"status": "Override applied", "command": current_command})


@app.route("/logs", methods=["GET"])
def logs():
    """Return detection & spray logs. Supports ?last=N filter."""
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
# MAIN
# ───────────────────────────────

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=True)
