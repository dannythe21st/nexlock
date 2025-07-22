#include <ESP32Servo.h>
#include <MFRC522.h>
#include <SPI.h>
#include <WiFi.h>
#include <time.h>
#include <Firebase_ESP_Client.h>

//sensor rfid
#define RST_PIN     22  
#define SDA_PIN     21  
#define SCK_PIN     18  
#define MOSI_PIN    23  
#define MISO_PIN    19  

//sensor movimento
int pir_pin = 27;
int state = LOW;             // by default, no motion detected
int val = 0;                 // variable to store the sensor status (value)


#define API_KEY "AIzaSyDyQ4_fUtDUO8t760uCzkYBk33lyAj32Mc"
#define DATABASE_URL "https://nexlock-5f286-default-rtdb.europe-west1.firebasedatabase.app/";

MFRC522 mfrc522(SDA_PIN, RST_PIN);

#define LED_R 15 // Pin red
#define LED_G 2  // Pin green
#define LED_B 4  // Pin blue

#define SERVO_PIN 12 

const int MAX_KEYS = 10;

Servo servo;

String validCards[MAX_KEYS]={};


//const char* ssid = "bitlogiclx";
//const char* password = "OMeuLindoFilho2002!";
//const char* ssid = "NOS-9712";
//const char* password = "Rc02021976";
const char* ssid = "Redmi 10 2022";
const char* password = "rms.costa349!12";

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long getAccessCardsMillis = 0;
unsigned long motionSensorMillis = 0;

int count = 0;
bool signupOK = false;
bool lock_state = true;
bool sentryMode_state = false;

void setupTime() {
    configTime(0, 0, "pool.ntp.org");
    Serial.println("Synching time...");
    while (!time(nullptr)) {
        Serial.print(".");
        delay(1000);
    }
    Serial.println("Time synched.");
}

String formatTime(time_t rawtime) {
    struct tm * ti;
    ti = localtime (&rawtime);
    char buffer[30];
    sprintf(buffer, "%02d-%02d-%04d %02d:%02d:%02d", ti->tm_mday, ti->tm_mon + 1, ti->tm_year + 1900, ti->tm_hour, ti->tm_min, ti->tm_sec);
    return String(buffer);
}

String formatDate(time_t rawtime) {
    struct tm * ti;
    ti = localtime (&rawtime);
    char buffer[30];
    sprintf(buffer, "%02d/%02d/%04d", ti->tm_mday, ti->tm_mon + 1, ti->tm_year + 1900);
    return String(buffer);
}

time_t parseDate(String dateString) {
    struct tm t = {0};
    sscanf(dateString.c_str(), "%02d/%02d/%04d", &t.tm_mday, &t.tm_mon, &t.tm_year);
    t.tm_mon -= 1;
    t.tm_year -= 1900;
    return mktime(&t);
}

void setup() {
  Serial.begin(9600);
  SPI.begin(SCK_PIN, MISO_PIN, MOSI_PIN, SDA_PIN);
  mfrc522.PCD_Init(); // Init RFID

  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);

  servo.attach(SERVO_PIN, 500, 2400);

  pinMode(pir_pin, INPUT); 

  initWifi();

  setupTime();

  initFirebase();

  Serial.println("setup DONE!");

}

void initWifi(){

  WiFi.begin(ssid, password);
  Serial.print("Connecting to ");
  Serial.println(ssid);

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void initFirebase()
{

    config.api_key = API_KEY;

    config.database_url = DATABASE_URL;

    String email = "rms.costa@campus.fct.unl.pt";
    String password = "123456";

    /* Sign up */
      if(Firebase.signUp(&config, &auth, "", "")) {
        Serial.println("Signed up to Firebase");
        signupOK = true;
      }else{
          Serial.printf("%s\n", config.signer.signupError.message.c_str());
      }

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void openLock(){
    digitalWrite(LED_G, HIGH);
    moveServo(90);
    digitalWrite(LED_G, LOW); 
}


void loop() {
   getHouseLocks();

  if(lock_state){
        closeServoLock();        
      }
      else{
        openServoLock();
      }
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    Serial.println("Card detected");

    String cardID = "";

    //read card
    for (byte i = 0; i < mfrc522.uid.size; i++) {
      cardID += String(mfrc522.uid.uidByte[i] < 0x10 ? " 0" : " ");
      cardID += String(mfrc522.uid.uidByte[i], HEX);
    }
    cardID.toUpperCase(); 
    cardID = cardID.substring(1);
    Serial.println("Card id: " + cardID);
 

    if (isValidCard(cardID)) {
      lock_state=!lock_state;
      if(!lock_state){
        Serial.println("open");
        sendAccessHistory(cardID,"open");
        openServoLock();
      }
      else{
        Serial.println("close");
        sendAccessHistory(cardID,"close");
        closeServoLock();
      }
      //carnaxide for proof of concept
      Firebase.RTDB.setBool(&fbdo, "houses/Carnaxide1715680461630/locks/front door/state",lock_state);

    } else {
      //invalid card/tag blink red 3 times
      for (int i = 0; i < 3; i++) {
        digitalWrite(LED_R, HIGH);
        delay(500);
        digitalWrite(LED_R, LOW);
        delay(500);
      }
    }
    mfrc522.PICC_HaltA();
  }
  motionDetection();
}



void sendAccessHistory(const String &cardID, String state) {
  if (Firebase.ready()) {
    String path = "houses/Carnaxide1715680461630/history";

    time_t now = time(nullptr);
    String formattedTime = formatTime(now);
    Serial.println("Detection time: " + formattedTime);
    
    if (Firebase.RTDB.getArray(&fbdo, path)) {
      FirebaseJsonArray arr = fbdo.jsonArray();
      FirebaseJson jsonObj;
      jsonObj.set("cardId", cardID);
      jsonObj.set("date", formattedTime);
      jsonObj.set("action", state);
      
      arr.add(jsonObj);

      // update db
      if (Firebase.RTDB.setArray(&fbdo, path.c_str(), &arr)) {
        Serial.println("Array updated successfully.");
      } else {
        Serial.println("Failed to update array.");
        Serial.println("Reason: " + fbdo.errorReason());
      }
    } else {
      Serial.println("Failed to get array.");

        FirebaseJsonArray arr = fbdo.jsonArray();
        FirebaseJson jsonObj;
        jsonObj.set("cardId", cardID);
        jsonObj.set("date", formattedTime);
        jsonObj.set("action", state);
        
        arr.add(jsonObj);

        // update db after error
        if (Firebase.RTDB.setArray(&fbdo, path.c_str(), &arr)) {
          Serial.println("Array updated successfully.");
        } else {
          Serial.println("Failed to update array.");
          Serial.println("Reason: " + fbdo.errorReason());
        }
      
    }
  }
}

String removeQuotes(String str) {
    String cleanedStr = "";
    for (int i = 0; i < str.length(); i++) {
        if (str[i] != '\"') {
            cleanedStr += str[i];
        }
    }
    return cleanedStr;
}

bool isCurrentTimeBetween(String from,String until){

  time_t now = time(nullptr);
  String formattedTime = formatDate(now);

  Serial.println("formattedTime:  "+formattedTime);
  Serial.println("from:  "+removeQuotes(from));
  Serial.println("until:  "+removeQuotes(until));

  time_t current_date = parseDate(formattedTime);
  time_t from_date =parseDate(removeQuotes(from));
  time_t until_date =parseDate(removeQuotes(until));

  return current_date>=from_date && current_date<=until_date;
  
}

void getAccessCards() {
  
if (Firebase.ready() && signupOK && (millis() - getAccessCardsMillis > 5000 || getAccessCardsMillis == 0)) {
  getAccessCardsMillis = millis();
    if (Firebase.RTDB.getJSON(&fbdo, "houses/Carnaxide1715680461630/cards")) {


      if (fbdo.dataType() == "json") {
        FirebaseJson* json = fbdo.jsonObjectPtr();
        String jsonString;
        json->toString(jsonString);
        Serial.println("Teste: "+jsonString);

        //card list
        String cardsIDList[MAX_KEYS]={}; 
         
        for (size_t i = 0; i < json->iteratorBegin(); i=i+5) {
          int type;
          String key, value;
          json->iteratorGet(i, type, key, value);
          Serial.println("Key: " + key );

          if (i < MAX_KEYS) {
            int stop = i+5;
            bool state=false;
            bool schedule_state=false;
            String from="";
            String until="";
            for (size_t j = i+1; j < json->iteratorBegin(); j++) {
              if(j==stop){
                break;
              }
              int type;
              String key2, value2;
              json->iteratorGet(j, type, key2, value2);

              if(key2=="state"){
                if(value2=="true"){
                  state=true;
                }
                else{
                  state=false;
                }
                
              }
              else if(key2=="schedule_state"){
                if(value2=="true"){
                  schedule_state=true;
                }
                else{
                  schedule_state=false;
                }
              }
              else if(key2=="from"){
                from=value2;
              }
              else if(key2=="until"){
                until=value2;
              }
            }


            if(state){
              if(schedule_state){
                if(isCurrentTimeBetween(from,until)){
                  cardsIDList[i] = key;
                }
                else{
                  Serial.println("Not authorized");
                }
                
              }
              else
                cardsIDList[i] = key;
            }
            else{
              Serial.println("Disabled card!!! ");
            }
            

          }
        }
        json->iteratorEnd();

        //store valid cars
        for (int i = 0; i < MAX_KEYS; ++i) {
          validCards[i] = cardsIDList[i];
        }
        
      }


    } else {
      Serial.println("Failed to get array.");
      Serial.println("Reason: " + fbdo.errorReason());
    }
  }
}

void getHouseLocks() {
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 2000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.getBool(&fbdo, "houses/Carnaxide1715680461630/locks/front door/state")) {
      auto value = fbdo.boolData();
      Serial.println("lock state: (front door - carnaxide) ->> "+String(value?"true":"false"));
      lock_state = value;
    }
    else {
      Serial.println(fbdo.errorReason());
    }


    if (Firebase.RTDB.getBool(&fbdo, "houses/Carnaxide1715680461630/sentryMode")) {
      auto value = fbdo.boolData();
      Serial.println("sentry mode state: (carnaxide) ->> "+String(value?"true":"false"));
      sentryMode_state = value;
    }
    else {
      Serial.println(fbdo.errorReason());
    }

  }
}

void motionDetection(){
  if(sentryMode_state && (millis() - motionSensorMillis > 10000 || motionSensorMillis == 0)){
    Serial.println("motionDetection()"); 

    val = digitalRead(pir_pin);
    if (val == HIGH) { 

      if (state == LOW) {
        Serial.println("Motion detected!"); 
        state = HIGH;
        sendAccessHistory("Motion Sensor","Motion Detected");
      }
    } 
    else {         
        if (state == HIGH){
          Serial.println("Motion stopped!");
          state = LOW;
      }
    }
  }
}

bool isValidCard(String cardID) {
  Serial.println("Valid card? ");

  getAccessCards();

  for (String validCard : validCards) {
    if (cardID == validCard) {
      return true;
    }
  }
  return false;
}

void moveServo(int angle) {
  servo.write(angle);
  delay(3000);
  servo.write(0);
}

void openServoLock() {
  digitalWrite(LED_G, HIGH);
  servo.write(90);
}

void closeServoLock() {
  digitalWrite(LED_G, LOW);
  servo.write(0);
}
