#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ================= BLE CONFIG =================
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_TX   "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_RX   "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

BLECharacteristic *txCharacteristic;
BLECharacteristic *rxCharacteristic;

bool deviceConnected = false;

// ================= MOTOR PINS =================
int motorPin1 = 25;
int motorPin2 = 26;

// ================= PWM =================
const int pwmFreq = 5000;
const int pwmResolution = 8;
const int pwmChannel1 = 0;
const int pwmChannel2 = 1;

// ================= MOTOR STATE =================
int motorLevel = 0;
bool motorEnabled = false;

// ================= TIMER =================
unsigned long timerStartMillis = 0;
unsigned long shutdownTime = 0;
bool timerRunning = false;

// ================= PRESSURE SENSOR =================
#define PRESSURE_PIN 34
int pressureThreshold = 2000;  // adjust based on calibration

bool pressureDetected = false;

// ================= SLEEP MODE =================
bool sleepMonitoring = false;

unsigned long sleepStartTime = 0;
unsigned long sleepEndTime = 0;

unsigned long noPressureStart = 0;
bool noPressureTimerActive = false;

// ================= BLE CALLBACKS =================

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Client connected");
  }

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Client disconnected");
    BLEDevice::startAdvertising();
  }
};

class RXCallbacks : public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic *pChar) {

    String rxValue = pChar->getValue().c_str();

    if (rxValue.length() <= 0) return;

    Serial.print("Received: ");
    Serial.println(rxValue);

    // ================= ON =================
    if (rxValue == "ON") {
      motorEnabled = true;
      sleepMonitoring = false;
      Serial.println("Motor ENABLED");
    }

    // ================= OFF → SLEEP MODE =================
    else if (rxValue == "OFF") {

      motorEnabled = false;
      sleepMonitoring = true;

      ledcWrite(pwmChannel1, 0);
      ledcWrite(pwmChannel2, 0);

      timerRunning = false;

      sleepStartTime = millis();
      noPressureTimerActive = false;
      noPressureStart = millis();

      Serial.println("Motor OFF → Sleep Monitoring STARTED");
    }

    // ================= SLEEP MODE (optional explicit command) =================
    else if (rxValue == "SLEEP_MODE") {

      motorEnabled = false;
      sleepMonitoring = true;

      ledcWrite(pwmChannel1, 0);
      ledcWrite(pwmChannel2, 0);

      sleepStartTime = millis();
      noPressureStart = millis();
      noPressureTimerActive = false;

      Serial.println("Sleep Mode Activated");
    }

    // ================= VIBRATION =================
    else if (rxValue.startsWith("VIB:")) {

      int level = rxValue.substring(4).toInt();
      motorLevel = map(level, 0, 100, 0, 255);

      Serial.print("PWM LEVEL: ");
      Serial.println(motorLevel);
    }

    // ================= TIMER =================
    else if (rxValue.startsWith("TIMER:")) {

      int seconds = rxValue.substring(6).toInt();

      if (seconds > 0) {
        shutdownTime = seconds * 1000UL;
        timerStartMillis = millis();
        timerRunning = true;
        motorEnabled = true;

        Serial.print("Timer started: ");
        Serial.print(seconds);
        Serial.println(" sec");
      }
    }

    // ================= BLE RESPONSE =================
    String reply = "Got: " + rxValue;
    txCharacteristic->setValue(reply.c_str());
    txCharacteristic->notify();
  }
};

// ================= SETUP =================

void setup() {

  Serial.begin(115200);

  pinMode(PRESSURE_PIN, INPUT);

  // PWM setup
  ledcSetup(pwmChannel1, pwmFreq, pwmResolution);
  ledcSetup(pwmChannel2, pwmFreq, pwmResolution);

  ledcAttachPin(motorPin1, pwmChannel1);
  ledcAttachPin(motorPin2, pwmChannel2);

  ledcWrite(pwmChannel1, 0);
  ledcWrite(pwmChannel2, 0);

  // BLE setup
  BLEDevice::init("ESP32_BLE");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  txCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_TX,
      BLECharacteristic::PROPERTY_NOTIFY);

  txCharacteristic->addDescriptor(new BLE2902());

  rxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_RX,
      BLECharacteristic::PROPERTY_WRITE);

  rxCharacteristic->setCallbacks(new RXCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);

  BLEDevice::startAdvertising();

  Serial.println("BLE Ready...");
}

// ================= PRESSURE CHECK =================

void checkPressure() {

  int sensorValue = analogRead(PRESSURE_PIN);

  if (sensorValue > pressureThreshold) {

    pressureDetected = true;
    noPressureTimerActive = false;

  } else {

    pressureDetected = false;

    if (!noPressureTimerActive) {
      noPressureStart = millis();
      noPressureTimerActive = true;
    }
  }
}

// ================= LOOP =================

unsigned long lastNotify = 0;

void loop() {

  // ===== HEARTBEAT =====
  if (deviceConnected && millis() - lastNotify > 5000) {
    lastNotify = millis();
    txCharacteristic->setValue("ESP32: heartbeat");
    txCharacteristic->notify();
  }

  // ===== TIMER STOP =====
  if (timerRunning) {

    if (millis() - timerStartMillis >= shutdownTime) {

      motorEnabled = false;
      timerRunning = false;

      ledcWrite(pwmChannel1, 0);
      ledcWrite(pwmChannel2, 0);

      Serial.println("Timer finished");
    }
  }

  // ===== MOTOR CONTROL =====
  if (motorEnabled && !sleepMonitoring) {

    ledcWrite(pwmChannel1, motorLevel);
    ledcWrite(pwmChannel2, motorLevel);

  } else {

    ledcWrite(pwmChannel1, 0);
    ledcWrite(pwmChannel2, 0);
  }

  // ===== SLEEP MONITORING =====
  if (sleepMonitoring) {

    checkPressure();

    // ===== 5 MIN NO PRESSURE RULE =====
    if (noPressureTimerActive &&
        millis() - noPressureStart >= 300000) {

      sleepEndTime = millis();
      sleepMonitoring = false;

      unsigned long duration =
        (sleepEndTime - sleepStartTime) / 60000;

      Serial.println("SLEEP ENDED");

      String result =
        "SLEEP:" +
        String(sleepStartTime) + "," +
        String(sleepEndTime) + "," +
        String(duration);

      txCharacteristic->setValue(result.c_str());
      txCharacteristic->notify();
    }
  }

  delay(20);
}