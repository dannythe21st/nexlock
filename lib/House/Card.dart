import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyCard extends StatelessWidget {
  final String title;
  final String houseId;
  final bool state;
  final databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;

  MyCard(this.title,this.houseId, this.state);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
          print('$title foi clicado : $houseId');
          Navigator.pushNamed(context, '/cardManagement',
              arguments: {'cardId':title,'houseId':houseId});
      },
      onLongPress: (){
        showDialog(context: context, builder: (BuildContext context){
          return AlertDialog(
            title: Text('Delete Card'),
            content: Text('Are you sure you want to delete it: $title'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  User? user = auth.currentUser;

                  if (user != null) {
                    databaseReference.child("houses").child(houseId).child("cards").child(title).remove().then((_) {

                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Continue'),
              ),
            ],
          );
        });
      },
      child: Card(
        margin: EdgeInsets.all(10.0),
        color: state ? Theme.of(context).cardColor : Colors.blueGrey,
        child: Container(
          width: 110.0,
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
