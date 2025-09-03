#include <ESP32Servo.h>
#include <WiFi.h>
#include <WebServer.h>

// Replace with your network credentials
const char* ssid = "Nothing Phone (2)_8358";
const char* password = "chikenscanfly";

// Create a WebServer object on port 80
WebServer server(80);

byte Servos[] = {22};

#define SERVO_COUNT sizeof(Servos)
Servo myServos[SERVO_COUNT];

const int DC_Pump = 2;

void OpenValveForSeconds(float duration, int servoIndex) {
  // Safety check: ensure the servo index is valid
  if (servoIndex < 0 || servoIndex >= SERVO_COUNT) {
    Serial.println("Error: Invalid Servo Index");
    return;
  }

  Serial.println("Starting pump...");
  digitalWrite(DC_Pump, HIGH); // 1. DC pump first starts

  delay(200); // Small delay to let the pump prime if needed

  Serial.print("Opening servo ");
  Serial.print(servoIndex);
  Serial.println(" to 5 degrees...");
  myServos[servoIndex].write(30); // 2. Servo of given index opens the valve

  Serial.print("Holding for ");
  Serial.print(duration);
  Serial.println(" seconds...");
  delay(duration * 1000); // Hold for the specified duration

  Serial.print("Closing servo ");
  Serial.println(servoIndex);
  myServos[servoIndex].write(0); // 3. Servo goes back to 0

  delay(500); // Wait for servo to physically move back

  Serial.println("Stopping pump.");
  digitalWrite(DC_Pump, LOW); // 4. DC pump stops
}

// Handler for the root URL
void handleRoot() {
  server.send(200, "text/plain", "esp32 is up!");
}

// Handler to process the servo and duration parameters
void handleServo() {
  // Check if both parameters exist in the request
  if (server.hasArg("duration") && server.hasArg("servoindex")) {
    // Get the 'duration' parameter and convert it to a float
    float duration = server.arg("duration").toFloat();

    // Get the 'servoindex' parameter and convert it to an integer
    int servoIndex = server.arg("servoindex").toInt();

    // --- You can now use the parsed values ---
    Serial.println("Received parameters:");
    Serial.print("Duration: ");
    Serial.println(duration);

    Serial.print("Servo Index: ");
    Serial.println(servoIndex);
    Serial.println("--------------------");

    // --- Trigger the main function with the parsed values ---
    OpenValveForSeconds(duration, servoIndex);

    // Send a success response back to the client
    String response = "Action complete for Duration: " + String(duration) + " and Servo Index: " + String(servoIndex);
    server.send(200, "text/plain", response);

  } else {
    // Send an error if parameters are missing
    server.send(400, "text/plain", "Bad Request: Missing 'duration' or 'servoindex' parameter.");
  }
}

void setup() {

  Serial.begin(115200);

    // --- Initialize Pump ---
  pinMode(DC_Pump, OUTPUT);
  digitalWrite(DC_Pump, LOW); // Keep pump off initially
 
  // Start Serial communication for debugging
  // Allow allocation of all timers for PWM
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  for (int i = 0; i < SERVO_COUNT; i++) {
    myServos[i].setPeriodHertz(50); // Standard servo frequency
    myServos[i].attach(Servos[i], 500, 2500); // Attach servo to its GPIO pin
    myServos[i].write(0); // Ensure all servos start at 0 degrees
  }
  
  delay(500); // Wait for servos to initialize

  // Connect to Wi-Fi
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  // Print the ESP32's IP address
  Serial.println("");
  Serial.println("WiFi connected.");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  // Define server routes
  server.on("/", handleRoot);
  server.on("/servo", HTTP_GET, handleServo); // New route for servo control

  // Start the server
  server.begin();
  Serial.println("HTTP server started");

}

void loop() {
  // put your main code here, to run repeatedly:
  server.handleClient();
}
