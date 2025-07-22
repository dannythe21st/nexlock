import 'package:flutter/material.dart';
import 'package:nexlock/LockControlFeature/LockControlPage.dart';
import 'package:nexlock/LoginFeature/LoginPage.dart';
import 'package:nexlock/Home/HomePage.dart';
import 'package:nexlock/House/HousePage.dart';
import 'package:nexlock/notificationsFeature/NotificationsPage.dart';
import 'package:nexlock/notificationsFeature/AuthUsersPage.dart';
import 'package:nexlock/ManageCardsFeature/CardManagementPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:nexlock/House/SharedHousePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexLock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      initialRoute: "/login",
      routes: {
        '/login': (context) => LoginPage(),
        '/lock_control': (context) => LockControlPage(),
        '/home': (context) => MyHomePage(),
        '/notifications': (context) => NotificationsPage(),
        '/house': (context) => HousePage(),
        '/sharedhouse': (context) => SharedHousePage(),
        '/cardManagement': (context) => CardManagementPage(),
        '/authusers': (context) => AuthUsersPage(),

      },
    );
  }
}

