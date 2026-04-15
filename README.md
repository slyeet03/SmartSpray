# SmartSpray 

An IoT integrated precision agriculture system that detects tomato plant diseases from images using a deep learning model and automatically triggers pesticide spraying via an ESP32-controlled hardware system.

---

## How It Works

1. A plant leaf image is captured via the Flutter app (camera) or a connected webcam
2. The image is sent to a Flask server running an InceptionV3 CNN model
3. The model classifies the disease from 6 possible categories
4. Based on the detected disease, a spray schedule determines the appropriate chemical, servo index, and spray duration
5. The Flask server sends an HTTP request to an ESP32 microcontroller over WiFi
6. The ESP32 opens the corresponding servo valve and runs the DC pump for the specified duration
7. The spray log and Gemini AI disease explanation are saved and accessible via the Flutter app

---


## Supported Diseases

| Disease | Chemical | Spray Time |
|---|---|---|
| Early Blight | Chlorothalonil | 5s |
| Late Blight | Metalaxyl | 4s |
| Leaf Mold | Mancozeb | 5s |
| Septoria Leaf Spot | Azoxystrobin | 2s |
| Yellow Leaf Curl Virus | No spray (resistant management) | — |
| Healthy | No spray | — |

---

## Tech Stack

**Machine Learning**
- Python, TensorFlow, InceptionV3 (transfer learning)
- OpenCV for image preprocessing
- Trained on PlantVillage dataset (tomato classes)
- 92%+ accuracy on test set

**Backend**
- Flask (Python)
- Gemini 2.0 Flash Lite API for disease explanations
- JSON-based logging with atomic file writes

**Hardware**
- ESP32 microcontroller running a WiFi HTTP server
- 3x servo valves (one per chemical container)
- 1x DC pump
- Arduino framework with ESP32Servo and WebServer libraries

**Mobile App**
- Flutter (Dart)
- Camera capture and image upload
- Manual spray control
- Spray history logs
- Gemini AI disease information screen

---

## Setup & Running

### 1. Python Environment

```bash
pip install flask tensorflow opencv-python numpy requests
```

### 2. Start the Flask Server

```bash
# Live mode (ESP32 enabled)
python -m server.app

# Test mode (ESP32 calls mocked)
python -m server.app -t
```

Server runs on `http://0.0.0.0:5001` by default.

### 3. Configure the ESP32

Open `esp32/PumpCode/PumpCode.ino` and fill in your WiFi credentials:

```cpp
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
```

Flash to your ESP32 via Arduino IDE. After connecting, note the IP address printed to Serial Monitor.

Then update `ESP32_URL` in `server/app.py`:

```python
ESP32_URL = "http://<your-esp32-ip>"
```

### 4. Configure the Flutter App

In `app/lib/services/api_service.dart`, update the base URL to point to your Flask server:

```dart
static String baseUrl = "http://<your-server-ip>:5001";
```

Then run the app:

```bash
cd app
flutter pub get
flutter run
```

---


## ESP32 Hardware API

The ESP32 exposes a simple HTTP GET endpoint:

```
GET /servo?duration=<seconds>&servoindex=<0|1|2>
```

**Example:**
```
http://192.168.1.100/servo?duration=4&servoindex=1
```

This opens servo at index 1, runs the DC pump for 4 seconds, then closes the valve and stops the pump.

---

## Circuit

Three servo valves (GPIO 16, 17, 18) each pinch a tube connected to a separate pesticide container. A single DC pump (GPIO 2) pressurizes the system. When a spray command arrives, the pump starts first, then the target servo opens, holds for the specified duration, closes, and the pump stops.

---

## Achievements

This project was built as part of the SmartSpray IoT + ML integration initiative at Manipal University Jaipur.

- 92% model accuracy on tomato disease classification
- End-to-end pipeline from image capture → ML inference → ESP32 actuation
- Gemini AI integration for farmer-friendly disease explanations
- Full Flutter mobile app with manual override and spray history

---

## Limitations

This project had several limitations including:

- Dataset was small so therefore sometimes the result was mismatched.
- Overfitting
- This Project was intending to go forward and utilise a CNC machine sort of implementation over crop field which lacked practicality and needs much more thought before execution.

