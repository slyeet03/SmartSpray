# SmartSpray Documentation

## 1. Overview

**SmartSpray** is an AI-powered precision agriculture system that detects plant diseases, recommends pesticide use, and controls spraying automatically via IoT.

* **Problem**: Farmers often spray pesticides uniformly, wasting chemicals and causing environmental harm. Disease identification in India requires sending images to agriculture departments, causing delays.
* **Solution**: SmartSpray uses a camera + ML to detect disease instantly, fetches recommended pesticide schedules, and uses an ESP32-controlled pump + servo to spray only when required. A mobile app lets farmers monitor plant health and manually control spraying.

## 2. System Architecture

### Components

1. **ESP32 (IoT Controller)**

   * Controls pump & servo.
   * Receives spray commands from Flask server.
   * Communicates over Wi-Fi.

2. **Webcam (Camera)**

   * Captures plant leaf images.
   * Images are sent to Flask server for ML analysis.

3. **Flask Server (Laptop/PC)**

   * Hosts ML model for plant disease classification.
   * Manages communication between ESP32 & Flutter app.
   * Stores logs & pesticide schedules in JSON.

4. **ML Model (TensorFlow/Keras)**

   * CNN trained on tomato leaf disease dataset.
   * Classifies disease and provides confidence.
   * Maps disease → recommended pesticide schedule.

5. **Flutter Mobile App**

   * Interfaces with Flask server via REST API.
   * Displays logs, disease info, spray history.
   * Allows manual override (trigger spray).

## 3. Hardware Setup

* **ESP32** → Wi-Fi enabled microcontroller.
* **Servo Motors** → Rotate to select chemical bottles via tube-switching.
* **Mini DC Pump** → Sprays liquid pesticide/water.
* **Relay Module** → Switches pump ON/OFF.
* **Power Supply** → 5V PSU or Power Bank.
* **Nozzles & Tubes** → Deliver controlled spray.
* **Multiple Bottles** → Store different pesticide solutions. Servo + tubing select correct bottle.

## 4. Software Components

### 4.1 Flask Server (`server/app.py`)

* Endpoints:

  * `/detect` → Receive image, run ML, return disease + spray plan.
  * `/command` → ESP32 polls to get latest spray command.
  * `/override` → Flutter app sends manual spray command.
  * `/logs` → Return spray/disease history.

* Uses:

  * `ml/model.py` → Loads trained CNN model (`.keras`).
  * `server/schedule.py` → Maps disease to chemical, spray time, servo index.
  * `server/logger.py` → Saves logs to JSON.

### 4.2 ML Model (`ml/model.py`)

* CNN trained on **Tomato Leaf Disease Dataset** (Kaggle).
* Input: RGB leaf image (224×224).
* Output: disease class + confidence.
* Classes hardcoded :

  * Tomato\_Early\_blight
  * Tomato\_Late\_blight
  * Tomato\_Leaf\_Mold
  * Tomato\_Septoria\_leaf\_spot
  * Tomato\_Yellow\_Leaf\_Curl\_Virus
  * Tomato\_healthy

### 4.3 Schedule (`server/schedule.py`)

* Defines pesticide recommendations for each disease:

  ```json
  {
    "Tomato_Early_Blight": {
      "disease": "Early Blight",
      "spray": true,
      "spray_time": 3,
      "servo_index": 1,
      "chemical": "Copper Oxychloride"
    }
  }
  ```
* Returned by `/detect`.

### 4.4 Logger (`server/logger.py`)

* Stores all detections & actions in `logs.json`.
* Example entry:

  ```json
  {
    "timestamp": "2025-09-03T00:45:00",
    "disease": "Late Blight",
    "confidence": 0.92,
    "spray": true,
    "spray_time": 4,
    "servo_index": 2,
    "chemical": "Chlorothalonil"
  }
  ```

### 4.5 Flutter Mobile App (`flutter_app/`)

#### Features:

* Connects to Flask server via REST (`http://10.0.2.2:5000` for emulator).
* Screens:

  * **Home** → Overview, quick actions.
  * **Logs** → View detection & spray history.
  * **Control** → Manual spray override.
  * (Future: Camera capture & upload).

#### Dependencies:

* `http` (API calls)
* `image_picker` (optional, for camera uploads)

#### Permissions (`AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## 5. Deployment & Testing

* ESP32 polls `/command` every few seconds.
* Activates relay → pump ON.
* Servo rotates → selects correct bottle.
* Pump sprays for `spray_time` seconds.


## 6. Workflow

1. Farmer takes picture (via camera or phone).
2. Flask server runs ML → detects disease.
3. Flask finds pesticide recommendation from schedule.
4. Log entry saved (`logs.json`).
5. ESP32 polls `/command` → executes spray.
6. Farmer monitors via mobile app.

## 7. Future Improvements

* Multi-crop disease dataset.
* Real-time field deployment with drones.
* Cloud server for multi-farm monitoring.
* Auto-mixing multiple chemicals.
* Offline ML inference on ESP32-CAM with TensorFlow Lite.

## 8. Folder Structure

```
SmartSpray/
│
├── ml/                  # Machine Learning
│   ├── model.py
│   ├── best_model.keras
│   └── train_model.ipynb
│   └── model.py
│
├── server/              # Flask Server
│   ├── app.py
│   ├── logger.py
│   ├── schedule.py
│   └── gemini_client.py
│
├── flutter_app/         # Flutter Application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── logs_screen.dart
│   │   │   └── control_screen.dart
│   └── android/...
│
├── logs.json            # Detection + spray logs
```

## 9. API Endpoints

* `POST /detect` → Upload image, return disease & spray recommendation.
* `GET /command` → ESP32 polls spray command.
* `POST /override` → App sends manual command.
* `GET /logs` → Fetch detection & spray history.
