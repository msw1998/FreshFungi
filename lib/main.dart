// ignore_for_file: prefer_const_constructors, unnecessary_new, prefer_const_literals_to_create_immutables

import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('FirebaseApp try');
    FirebaseApp app;
    List<FirebaseApp> firebase = Firebase.apps;
    for (FirebaseApp appd in firebase) {
      print(appd.name);
    }
    print('FirebaseApp starting initilize');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Initialization completed');
  } finally {
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: <String, WidgetBuilder>{
        '/Home': (BuildContext context) => HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double co2_percent = 0.0;
  double hum_percent = 0.0;
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref("data");
  String co2 = '...';
  String humid = '...';
  String temp = '...';
  @override
  void initState() {
    super.initState();

    initRealTimeDb();
  }

  @override
  void dispose() {
    databaseReference;
    super.dispose();
  }

  void initRealTimeDb() async {
    databaseReference.onValue.listen((DatabaseEvent event) {
      var data = event.snapshot.children;
      print("Value changed $data");
      print("Length ${data.length}");

      List date = data.map((e) {
        return e.value;
      }).toList();

      print(date[0]);

      // ignore: avoid_print
      setState(() {
        co2 = '${date[0]} ppm';
        temp = '${date[2]} °C';
        humid = '${date[1]}%';
        co2_percent = (date[0] - 0) / (2000 - 0);
        if (co2_percent > 1.0) {
          co2_percent = 1.0;
        }
        hum_percent = date[1] / 100;
        if (hum_percent > 1.0) {
          hum_percent = 1.0;
        }
        print(co2_percent);
        // co2 = '${event.snapshot.children.first.value} ppm';
        // humid = '${data['co2']}%';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(),
                ),
              );
            },
          ),
          SizedBox(
            width: 5,
          )
        ],
        backgroundColor: Color.fromARGB(255, 255, 204, 0),
        title: Center(
          child: Text(
            'Mushroom Monitoring',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40),
            ),
            CircularPercentIndicator(
              arcBackgroundColor: Colors.grey[300],
              arcType: ArcType.FULL,
              startAngle: 210,
              radius: 80.0,
              lineWidth: 10.0,
              percent: co2_percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.co2_sharp,
                    size: 50.0,
                    color: Colors.green[400],
                  ),
                  Text(
                    co2,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  // Text("580 ppm"),
                ],
              ),
              backgroundColor: Colors.grey,
              progressColor: Colors.green[400],
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 10.0,
              percent: hum_percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 50.0,
                    color: Colors.blue,
                  ),
                  Text(
                    humid,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  // Text("80 %"),
                ],
              ),
              backgroundColor: Colors.grey,
              progressColor: Colors.blue,
            ),
            Padding(padding: EdgeInsets.only(top: 40)),
            Icon(
              CupertinoIcons.thermometer,
              size: 80.0,
              color: Colors.red[600],
            ),
            Padding(padding: EdgeInsets.only(top: 10)),
            Text(
              temp,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late int inputCO2 = 0;
  late double inputHumidity = 19.0;
  late TextEditingController _co2Controller;
  late TextEditingController _humidityController;
  bool isLoading = false;
  DatabaseReference thresholdRef =
      FirebaseDatabase.instance.ref("data/threshold");

  @override
  void initState() {
    initRealTimeDb();
    _co2Controller = TextEditingController(text: inputCO2.toString());
    _humidityController = TextEditingController(text: inputHumidity.toString());
    super.initState();
  }

  @override
  void dispose() {
    _co2Controller.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  void initRealTimeDb() async {
    final snapshot = await thresholdRef.get();
    final threholddata = snapshot.value as Map<dynamic, dynamic>;
    print("Threshold Dataaaa:////////////");
    print(threholddata);
    setState(() {
      inputCO2 = threholddata["thresholdco2"];
      _co2Controller.text = inputCO2.toString();

      inputHumidity = threholddata["thresholdhumidity"].toDouble();
      _humidityController.text = inputHumidity.toString();
    });
  }

  void _saveSettings() async {
    print(inputCO2);
    print(inputHumidity);
    await thresholdRef.set({
      'thresholdco2': inputCO2,
      'thresholdhumidity': inputHumidity,
    });
    // TODO: Save the updated settings
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 204, 0),
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _co2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CO2',
                hintText: 'Enter CO2 Threshold',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _humidityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Humidity',
                hintText: 'Enter Humidity Threshold',
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black)),
              onPressed: () async {
                setState(() {
                  isLoading = true;
                  inputCO2 = int.parse(_co2Controller.text);
                  inputHumidity = double.parse(_humidityController.text);
                });
                _saveSettings();
                setState(() {
                  isLoading = false;
                });
              },
              child: isLoading == false
                  ? Text(
                      'Save'.toUpperCase(),
                    )
                  : CircularProgressIndicator(
                      color: Colors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacementNamed('/Home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/logo.png',
              width: 80,
              height: 80,
            ),
            SizedBox(height: 10),
            Text(
              'Mushroom Cultivation Monitoring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              backgroundColor: Color.fromARGB(255, 255, 204, 0),
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
