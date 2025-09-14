"""
File: app.py
Flask server for SmartSpray.
Handles ML predictions, spray scheduling, ESP32 communication,
Gemini explanations, and app API for logs + manual control + webcam capture.
"""

import os
import cv2
import numpy as np
import requests
from flask import Flask, request, jsonify
from server.gemini_client import get_disease_info
import json
import sys 
import signal
import time

from ml.model import predict_image
from server.schedule import get_recommendation
from server.logger import save_log, load_logs

# Flask app
app = Flask(__name__)

# ⚡ CHANGE THIS to match the ESP32's IP from Serial Monitor
ESP32_URL = "http://10.230.158.86"  

# ───────────────────────────────
# TEST MODE FLAG
# ───────────────────────────────
TEST_MODE = "-t" in sys.argv or "--test" in sys.argv
if TEST_MODE:
    print("⚠️ Running in TEST MODE — ESP32 requests will be mocked.")

# ───────────────────────────────
# HELPER FUNCTIONS FOR FILE HANDLING
# ───────────────────────────────

def safe_json_load(filepath):
    """Safely load JSON file, return empty list if file doesn't exist or is corrupted"""
    if not os.path.exists(filepath):
        return []
    
    try:
        with open(filepath, 'r') as f:
            # Check if file is empty
            if os.path.getsize(filepath) == 0:
                return []
            content = f.read().strip()
            if not content:  # Empty file
                return []
            return json.loads(content)
    except (json.JSONDecodeError, ValueError):
        print(f"Warning: {filepath} is corrupted. Resetting to empty list.")
        return []
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return []

def safe_json_save(filepath, data):
    """Safely save data to JSON file"""
    try:
        # Ensure directory exists
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        # Write to temporary file first
        temp_file = filepath + '.tmp'
        with open(temp_file, 'w') as f:
            json.dump(data, f, indent=2)
        
        # Replace original file
        if os.path.exists(filepath):
            os.remove(filepath)
        os.rename(temp_file, filepath)
        
    except Exception as e:
        print(f"Error saving {filepath}: {e}")

# ───────────────────────────────
# ROUTES
# ───────────────────────────────

@app.route("/")
def index():
    return jsonify({"message": f"SmartSpray server running (TEST_MODE={TEST_MODE})"})


@app.route("/detect", methods=["POST"])
def detect():
    """Handle plant image upload from Flutter app."""
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    try:
        file = request.files["image"]
        npimg = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
        
        if frame is None:
            return jsonify({"error": "Failed to decode image"}), 400

        return process_and_act(frame, source="Upload")
    except Exception as e:
        return jsonify({"error": f"Image processing error: {str(e)}"}), 500


@app.route("/capture", methods=["GET"])
def capture():
    """Capture image from laptop webcam and run ML."""
    cap = cv2.VideoCapture(0)  # 0 = default webcam
    if not cap.isOpened():
        return jsonify({"error": "Webcam not accessible"}), 500

    try:
        ret, frame = cap.read()
        if not ret:
            return jsonify({"error": "Failed to capture frame"}), 500

        return process_and_act(frame, source="Webcam")
    finally:
        cap.release()

@app.route('/shutdown', methods=['POST', 'GET'])
def shutdown():
    """Shutdown the server gracefully"""
    def shutdown_server():
        time.sleep(1)
        os._exit(0)
    
    import threading
    threading.Thread(target=shutdown_server).start()
    return 'Server shutting down...'

@app.route("/gemini_info", methods=["GET"])
def gemini_info():
    """Return stored Gemini disease info from data/gemini_info.json"""
    data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
    gemini_file = os.path.join(data_dir, "gemini_info.json")

    history = safe_json_load(gemini_file)
    return jsonify(history)


@app.route("/override", methods=["POST"])
def override():
    """Manual override from Flutter app."""
    try:
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
    except Exception as e:
        return jsonify({"error": f"Override error: {str(e)}"}), 500


@app.route("/logs", methods=["GET"])
def logs():
    """Return detection & spray logs."""
    try:
        logs = load_logs()
        last = request.args.get("last")
        if last:
            try:
                n = int(last)
                logs = logs[-n:]
            except ValueError:
                pass
        return jsonify(logs)
    except Exception as e:
        return jsonify({"error": f"Error loading logs: {str(e)}"}), 500

# ───────────────────────────────
# HELPERS
# ───────────────────────────────

def process_and_act(frame, source="Unknown"):
    from datetime import datetime
    
    try:
        data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
        os.makedirs(data_dir, exist_ok=True)

        filename = f"capture_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        img_path = os.path.join(data_dir, filename)
        cv2.imwrite(img_path, frame)

        # Predict disease
        result = predict_image(img_path)  # {"disease": "...", "confidence": ...}
        recommendation = get_recommendation(result["disease"])

        # 🔹 Call Gemini for info
        gemini_info = get_disease_info(result["disease"])

        # 🔹 Save Gemini info to JSON
        gemini_file = os.path.join(data_dir, "gemini_info.json")
        history = safe_json_load(gemini_file)
        
        entry = {
            "timestamp": datetime.now().isoformat(),
            "disease": result["disease"],
            "confidence": result["confidence"],
            "gemini_info": gemini_info.get("gemini_info", "No info"),
        }
        history.append(entry)
        
        safe_json_save(gemini_file, history)

        # Create log entry
        log_entry = {
            "source": source,
            "disease": recommendation["disease"],
            "confidence": result["confidence"],
            "spray": recommendation["spray"],
            "spray_time": recommendation["spray_time"],
            "servo_index": recommendation["servo_index"],
            "chemical": recommendation["chemical"],
            "amount": recommendation["amount"],
            "gemini_info": gemini_info.get("gemini_info", "No info")  # add to log too
        }

        if recommendation["spray"]:
            log_entry["esp32_response"] = send_to_esp32(
                recommendation["spray_time"], recommendation["servo_index"]
            )

        save_log(log_entry)

        return jsonify({
            "prediction": result,
            "recommendation": recommendation,
            "gemini": gemini_info,
            "log": log_entry
        })
        
    except Exception as e:
        return jsonify({"error": f"Processing error: {str(e)}"}), 500


def send_to_esp32(duration, servo_index):
    """Send spray command to ESP32, or mock if in test mode."""
    if TEST_MODE:
        return f"[TEST MODE] Would spray for {duration}s on servo {servo_index}"

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
    import sys, os

    # 👇 check if SMARTSPRAY_TEST=1 or `-t` flag
    TEST_MODE = (
        "-t" in sys.argv or os.environ.get("SMARTSPRAY_TEST", "0") == "1"
    )

    if TEST_MODE:
        print("🚀 Running in TEST MODE (ESP32 calls mocked)")
    else:
        print("✅ Running in LIVE MODE (ESP32 enabled)")

    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=True)