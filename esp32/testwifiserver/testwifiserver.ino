#include <WiFi.h>
#include <WebServer.h>

// Replace with your network credentials
const char* ssid = "";
const char* password = "";

// Create a WebServer object on port 80
WebServer server(80);

// Define the GPIO pin connected to the LED
const int ledPin = 2;

// Handler for the root URL
void handleRoot() {
  server.send(200, "text/plain", "esp32 is up!");
}

// Handler for the /on URL
void handleOn() {
  digitalWrite(ledPin, HIGH); // Turn the LED on
  server.send(200, "text/plain", "LED has been turned ON");
}

// Handler for the /off URL (good practice to have an off switch)
void handleOff() {
  digitalWrite(ledPin, LOW); // Turn the LED off
  server.send(200, "text/plain", "LED has been turned OFF");
}

void setup() {
  // Start Serial communication for debugging
  Serial.begin(115200);

  // Set the LED pin as an output
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW); // Keep LED off initially

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
  server.on("/on", handleOn);
  server.on("/off", handleOff); // Route to turn the LED off

  // Start the server
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  // Handle client requests
  server.handleClient();
}
