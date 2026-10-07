# Cyber-Physical IoT Hardware Specification — AgroNexus

This document specifies the micro-controller hardware node architecture, sensor pinouts, embedded C++ firmware implementation, and telemetry payload formats for the **AgroNexus** crop storage monitoring module.

---

## 1. Hardware Node Components & Pinout Schematic

The IoT hardware sensing node consists of an **ESP32 Wi-Fi / Bluetooth Microcontroller** connected to environmental sensors for monitoring crop storage facilities:

| Component | Function | Interface / Pin Assignment |
| :--- | :--- | :--- |
| **ESP32 NodeMCU** | Central Controller & Wi-Fi Client | Dual-core Tensilica LX6, 240MHz |
| **DHT22 Sensor** | Precision Temperature & Relative Humidity | `GPIO 4` (Digital Input) |
| **MQ-135 Sensor** | Gas Quality (Ethylene / Ammonia / CO2) | `GPIO 34` (ADC Channel 1 Analog Input) |
| **Status LED / Buzzer**| Local Safety Alert Threshold Indicator | `GPIO 2` (Digital Output) |
| **Power Supply** | External Power Input | 5V DC via Micro-USB / LiFePO4 battery |

---

## 2. Hardware Circuit Pinout Configuration

```
+-------------------------------------------------------------+
|                          ESP32                              |
|                                                             |
|  [GPIO 4]  <-------------- Data Pin ------------- [DHT22]   |
|  [GPIO 34] <-------------- Analog Out (AO) -------- [MQ-135]  |
|  [5V VCC]  ---------------- VCC (Power 5V) -------- [Sensors] |
|  [GND]     ---------------- Common Ground (GND) --- [Sensors] |
|  [GPIO 2]  --------------> Status LED / Buzzer               |
+-------------------------------------------------------------+
```

---

## 3. Embedded C++ Firmware Implementation (Arduino Framework)

Below is the complete production-grade C++ code for the ESP32 node:

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ135_PIN 34
#define ALERT_LED_PIN 2

DHT dht(DHTPIN, DHTTYPE);

// Wi-Fi Credentials & Endpoint Setup
const char* ssid = "AgroNexus_Mesh";
const char* password = "SecureStorageKey";
const char* serverEndpoint = "https://api.agronexus.io/v1/telemetry";
const char* nodeId = "STORAGE_UNIT_01";

// Safety Thresholds (FAO Crop Storage Recommendations)
const float MAX_TEMP_CELSIUS = 25.0;
const float MAX_HUMIDITY_PERCENT = 75.0;
const int MAX_GAS_PPM = 400;

void setup() {
    Serial.begin(115200);
    pinMode(ALERT_LED_PIN, OUTPUT);
    dht.begin();

    WiFi.begin(ssid, password);
    Serial.print("Connecting to Wi-Fi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nConnected to Wi-Fi Network. IP: " + WiFi.localIP().toString());
}

void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        float humidity = dht.readHumidity();
        float temperature = dht.readTemperature();
        int gasLevel = analogRead(MQ135_PIN);

        if (isnan(humidity) || isnan(temperature)) {
            Serial.println("Failed to read from DHT sensor!");
            delay(5000);
            return;
        }

        bool alertTriggered = (temperature > MAX_TEMP_CELSIUS) || 
                              (humidity > MAX_HUMIDITY_PERCENT) || 
                              (gasLevel > MAX_GAS_PPM);

        digitalWrite(ALERT_LED_PIN, alertTriggered ? HIGH : LOW);

        // JSON Telemetry Payload Synthesis
        String jsonPayload = "{";
        jsonPayload += "\"nodeId\":\"" + String(nodeId) + "\",";
        jsonPayload += "\"temperature\":" + String(temperature, 2) + ",";
        jsonPayload += "\"humidity\":" + String(humidity, 2) + ",";
        jsonPayload += "\"gasLevel\":" + String(gasLevel) + ",";
        jsonPayload += "\"isAlertTriggered\":" + String(alertTriggered ? "true" : "false");
        jsonPayload += "}";

        // Send HTTP POST Request
        HTTPClient http;
        http.begin(serverEndpoint);
        http.addHeader("Content-Type", "application/json");

        int httpResponseCode = http.POST(jsonPayload);
        Serial.println("Telemetry Ingest Status: " + String(httpResponseCode));
        http.end();
    }

    delay(15000); // Send telemetry log every 15 seconds
}
```

---

## 4. Telemetry JSON Payload Format

```json
{
  "nodeId": "STORAGE_UNIT_01",
  "temperature": 26.50,
  "humidity": 78.20,
  "gasLevel": 420,
  "isAlertTriggered": true
}
```

## 5. Equipment request status and hardware integration

The Agronomist interface can save `AERATION_START` and `UV_DECONTAMINATION` requests for a discovered node. These records are persisted with `PENDING_DEVICE` status for visibility and audit. The backend does **not** dispatch requests to an ESP32, control a relay, or claim that equipment has been activated.

Executing requests requires a separately designed device transport and authentication scheme, device-side allowlists and safety interlocks, delivery/retry rules, and device acknowledgements. Until that integration and its operational safety review exist, requests remain pending and must not be treated as equipment state.
