#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include <WiFiClientSecure.h>

const char* ssid = "ssid";
const char* password = "wlan_password";

const char* mqtt_server = "server_ip";
const int mqtt_port = 8883;
const char* mqtt_user = "mqtt_user";
const char* mqtt_password = "mqtt_password";

// CA certificate
const char* rootCA PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
your_cerificate
-----END CERTIFICATE-----
)EOF";

WiFiClientSecure espClient;
PubSubClient client(espClient);

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 3600, 60000);

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connect to WLAN: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

// Get client ID based on Mac adress
String getUniqueClientId() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  String clientId = "ESP32-";
  clientId += String(mac[0], HEX);
  clientId += String(mac[1], HEX);
  clientId += String(mac[2], HEX);
  clientId += String(mac[3], HEX);
  clientId += String(mac[4], HEX);
  clientId += String(mac[5], HEX);
  return clientId;
}

void reconnect() {
  int attempts = 0;
  while (!client.connected() && attempts < 3) {
    attempts++;
    String clientId = getUniqueClientId();
    Serial.print("Trying MQTT Connection with ID ");
    Serial.print(clientId);
    Serial.print(" (Attempt ");
    Serial.print(attempts);
    Serial.print("/3)...");
    
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
      Serial.println("connected!");
    } else {
      Serial.print("Error, rc=");
      Serial.print(client.state());
      
      switch(client.state()) {
        case -4: 
          Serial.println(" (Connection timeout)");
          break;
        case -3: 
          Serial.println(" (Connection lost)");
          break;
        case -2: 
          Serial.println(" (Connection failed)");
          break;
        case -1: 
          Serial.println(" (Connection refused: unacceptable protocol version)");
          break;
        case 1: 
          Serial.println(" (Connection refused: incorrect client ID)");
          break;
        case 2: 
          Serial.println(" (Connection refused: server unavailable)");
          break;
        case 3: 
          Serial.println(" (Connection refused: bad username or password)");
          break;
        case 4: 
          Serial.println(" (Connection refused: not authorized)");
          break;
        case 5: 
          Serial.println(" (Connection refused: not authorized)");
          break;
        default: 
          Serial.println(" (Unknown error)");
          break;
      }
      
      Serial.println("Trying again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  
  Serial.println("Setting up TLS connection...");
  espClient.setCACert(rootCA);
  
  Serial.print("Setting up MQTT server connection to ");
  Serial.print(mqtt_server);
  Serial.print(":");
  Serial.println(mqtt_port);
  
  client.setServer(mqtt_server, mqtt_port);

  client.setBufferSize(512); //bigger buffer for tls overhead

  timeClient.begin();
  timeClient.update(); 
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  
  if (!client.connected()) {
    Serial.println("MQTT connection still failed. Retrying in 10 seconds...");
    delay(10000);
    return;
  }
  
  client.loop();

  // Sending test data
  static unsigned long lastSendTime = 0;
  unsigned long currentMillis = millis();
  
  if (currentMillis - lastSendTime > 5000) {
    lastSendTime = currentMillis;
    
    timeClient.update();
    unsigned long timestamp = timeClient.getEpochTime();

    float value = 23.4 + (random(-100, 100) / 100.0);

    StaticJsonDocument<128> doc;
    doc["value"] = value;
    doc["timestamp"] = timestamp;
    doc["device_id"] = getUniqueClientId();

    char payload[128];
    serializeJson(doc, payload);

    // Publish data
    Serial.print("Publishing to esp32/test: ");
    Serial.println(payload);
    
    if (client.publish("esp32/test", payload)) {
      Serial.println("Publish successful");
    } else {
      Serial.println("Publish failed");
    }
  }
}
