import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class MySharedCardLock extends StatelessWidget {
  final databaseReference = FirebaseDatabase.instance.ref();
  final String lockId;
  final bool state;
  final String houseId;

  MySharedCardLock(this.lockId, this.state, this.houseId);

  @override
  Widget build(BuildContext context) {
    Color cardColor = state ? Colors.red : Colors.green;
    return GestureDetector(
      onTap: () {
        print('$lockId foi clicado');
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: Text(lockId),
            content: Text(state ? 'Do you want to unlock it?' : 'Do you want to lock it?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await databaseReference
                        .child("houses")
                        .child(houseId)
                        .child("locks")
                        .child(lockId)
                        .update({
                      'state': !state,
                    });
                    print("Lock updated successfully!");
                  } catch (error) {
                    print("Something went wrong while updating a lock");
                    print(error);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(state ? 'Unlock' : 'Lock'),
              ),
            ],
          );
        });
      },
      child: Card(
        margin: EdgeInsets.all(10.0),
        color: cardColor,
        child: Container(
          width: 110.0,
          child: Center(
            child: Text(
              lockId,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
