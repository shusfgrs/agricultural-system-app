#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <DHT.h>
#include <ArduinoJson.h>

#define DHTPIN 4
#define DHTTYPE DHT11
#define SOIL_MOISTURE_PIN 34
#define LIGHT_SENSOR_PIN 35
#define WATER_LEVEL_PIN 32
#define CO2_PIN 33
#define IRRIGATION_RELAY_PIN 25
#define LIGHT_RELAY_PIN 26

#define SERVICE_UUID "4fafc201-1fb7-4597-8fcd-2c3b7a8e6b5a"
#define CHARACTERISTIC_UUID_TX "beb5483e-36e1-4688-b7f5-ebd7e6e7c1d3"
#define CHARACTERISTIC_UUID_RX "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
BLECharacteristic* pRxCharacteristic = NULL;

bool deviceConnected = false;
bool oldDeviceConnected = false;

DHT dht(DHTPIN, DHTTYPE);

struct SensorData {
  float temperature;
  float humidity;
  int soilMoisture;
  int lightLevel;
  int waterLevel;
  int co2;
  unsigned long timestamp;
};

struct ControlState {
  bool irrigationOn;
  bool lightOn;
  int brightness;
  int targetMoisture;
};

SensorData sensorData;
ControlState controlState;

unsigned long lastSensorUpdate = 0;
const long sensorUpdateInterval = 2000;

unsigned long lastDataSend = 0;
const long dataSendInterval = 3000;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue().c_str();
      
      if (rxValue.length() > 0) {
        Serial.print("Received: ");
        Serial.println(rxValue);
        
        StaticJsonDocument<200> doc;
        DeserializationError error = deserializeJson(doc, rxValue);
        
        if (!error) {
          const char* cmd = doc["cmd"];
          int value = doc["value"];
          handleCommand(cmd, value);
        }
      }
    }
};

void handleCommand(const char* cmd, int value) {
  if (strcmp(cmd, "irrigation") == 0) {
    controlState.irrigationOn = (value == 1);
    digitalWrite(IRRIGATION_RELAY_PIN, controlState.irrigationOn ? HIGH : LOW);
    Serial.printf("Irrigation: %s\n", controlState.irrigationOn ? "ON" : "OFF");
  }
  else if (strcmp(cmd, "light") == 0) {
    controlState.lightOn = (value == 1);
    digitalWrite(LIGHT_RELAY_PIN, controlState.lightOn ? HIGH : LOW);
    Serial.printf("Light: %s\n", controlState.lightOn ? "ON" : "OFF");
  }
  else if (strcmp(cmd, "brightness") == 0) {
    controlState.brightness = value;
    Serial.printf("Brightness: %d%%\n", controlState.brightness);
  }
  else if (strcmp(cmd, "target_moisture") == 0) {
    controlState.targetMoisture = value;
    Serial.printf("Target moisture: %d%%\n", controlState.targetMoisture);
  }
}

int readCO2() {
  int co2Raw = analogRead(CO2_PIN);
  return map(co2Raw, 0, 4095, 400, 2000);
}

void readSensors() {
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  if (!isnan(temp)) {
    sensorData.temperature = temp;
  }
  if (!isnan(hum)) {
    sensorData.humidity = hum;
  }
  
  int soilRaw = analogRead(SOIL_MOISTURE_PIN);
  sensorData.soilMoisture = map(soilRaw, 4095, 0, 0, 100);
  
  int lightRaw = analogRead(LIGHT_SENSOR_PIN);
  sensorData.lightLevel = map(lightRaw, 0, 4095, 0, 1000);
  
  int waterRaw = analogRead(WATER_LEVEL_PIN);
  sensorData.waterLevel = map(waterRaw, 0, 4095, 0, 100);
  
  sensorData.co2 = readCO2();
  
  sensorData.timestamp = millis();
  
  Serial.println("=== Sensor Data ===");
  Serial.printf("Temperature: %.1f C\n", sensorData.temperature);
  Serial.printf("Humidity: %.1f %%\n", sensorData.humidity);
  Serial.printf("Soil Moisture: %d %%\n", sensorData.soilMoisture);
  Serial.printf("Light Level: %d lux\n", sensorData.lightLevel);
  Serial.printf("Water Level: %d %%\n", sensorData.waterLevel);
  Serial.printf("CO2: %d ppm\n", sensorData.co2);
  Serial.println("===================");
}

void sendSensorData() {
  if (!deviceConnected) {
    return;
  }
  
  StaticJsonDocument<256> doc;
  doc["temperature"] = sensorData.temperature;
  doc["humidity"] = sensorData.humidity;
  doc["soilMoisture"] = sensorData.soilMoisture;
  doc["lightLevel"] = sensorData.lightLevel;
  doc["waterLevel"] = sensorData.waterLevel;
  doc["co2"] = sensorData.co2;
  doc["timestamp"] = sensorData.timestamp;
  
  char jsonBuffer[300];
  serializeJson(doc, jsonBuffer);
  
  pTxCharacteristic->setValue(jsonBuffer);
  pTxCharacteristic->notify();
  
  Serial.print("Sent data: ");
  Serial.println(jsonBuffer);
}

void autoControl() {
  if (sensorData.soilMoisture < controlState.targetMoisture - 5) {
    if (!controlState.irrigationOn) {
      controlState.irrigationOn = true;
      digitalWrite(IRRIGATION_RELAY_PIN, HIGH);
      Serial.println("Auto: Irrigation ON");
    }
  } else if (sensorData.soilMoisture >= controlState.targetMoisture) {
    if (controlState.irrigationOn) {
      controlState.irrigationOn = false;
      digitalWrite(IRRIGATION_RELAY_PIN, LOW);
      Serial.println("Auto: Irrigation OFF");
    }
  }
  
  if (sensorData.lightLevel < 200) {
    if (!controlState.lightOn) {
      controlState.lightOn = true;
      digitalWrite(LIGHT_RELAY_PIN, HIGH);
      Serial.println("Auto: Light ON");
    }
  } else if (sensorData.lightLevel > 800) {
    if (controlState.lightOn) {
      controlState.lightOn = false;
      digitalWrite(LIGHT_RELAY_PIN, LOW);
      Serial.println("Auto: Light OFF");
    }
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Smart Agriculture System...");
  
  pinMode(IRRIGATION_RELAY_PIN, OUTPUT);
  pinMode(LIGHT_RELAY_PIN, OUTPUT);
  digitalWrite(IRRIGATION_RELAY_PIN, LOW);
  digitalWrite(LIGHT_RELAY_PIN, LOW);
  
  controlState.irrigationOn = false;
  controlState.lightOn = false;
  controlState.brightness = 50;
  controlState.targetMoisture = 50;
  
  sensorData.co2 = 450;
  
  dht.begin();
  
  BLEDevice::init("SmartAgriculture-ESP32");
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pTxCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_TX,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pTxCharacteristic->addDescriptor(new BLE2902());
  
  pRxCharacteristic = pService->createCharacteristic(
                       CHARACTERISTIC_UUID_RX,
                       BLECharacteristic::PROPERTY_WRITE
                     );
  pRxCharacteristic->setCallbacks(new MyCallbacks());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE started. Waiting for connection...");
  Serial.println("Device name: SmartAgriculture-ESP32");
}

void loop() {
  unsigned long currentMillis = millis();
  
  if (currentMillis - lastSensorUpdate >= sensorUpdateInterval) {
    lastSensorUpdate = currentMillis;
    readSensors();
    autoControl();
  }
  
  if (currentMillis - lastDataSend >= dataSendInterval) {
    lastDataSend = currentMillis;
    sendSensorData();
  }
  
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Restart advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  delay(100);
}
