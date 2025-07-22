import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDrawer extends StatelessWidget {
  final String currentPage;

  const MyDrawer({Key? key, required this.currentPage}) : super(key: key);

  void userSignOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Home'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),

          ListTile(
            title: Text('My account'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            title: Text('Logout',style: TextStyle(
              color: Colors.red,
            ),),
            onTap: () {
              userSignOut();
              // Limpa o histórico de navegação e retorna para a página de login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),


        ],
      ),
    );
  }
}
