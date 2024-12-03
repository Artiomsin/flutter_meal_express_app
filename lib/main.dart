import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rapid_gourmet/Page/myhome_page.dart';

/*
import'basic_page.dart';
import'profile_page.dart';
import 'cart_page.dart';
import 'history_page.dart';
import 'messages_page.dart';
import 'promotions_page.dart';
*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Ошибка инициализации Firebase: $e');
  }
  runApp(MyApp());
}
 final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speed App',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: const Color.fromARGB(142, 255, 255, 255),
          selectionHandleColor: Colors.white,
        ),
      ),
      navigatorKey: navigatorKey,
      home: MyHomePage(),
    );
  }
}
