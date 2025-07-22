import 'package:flutter/material.dart';
import 'package:nexlock/util/Drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CardManagementPage extends StatefulWidget {
  @override
  State<CardManagementPage> createState() => _CardManagementPage();
}

class _CardManagementPage extends State<CardManagementPage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late String houseId=" ";
  late String cardId=" ";
  late bool cardState=false;
  late bool scheduleState=false;
  late String from = "";
  late String until = "";
  
  bool getCard = false;

  final _fromDateController = TextEditingController();
  final _untilDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void getCardInfo(){
    getCard = true;

    databaseReference
        .child("houses")
        .child(this.houseId)
        .child("cards")
        .child(this.cardId)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> cardData =
        snapshot.value as Map<dynamic, dynamic>;

        if (cardData.isNotEmpty) {
          setState(() {
            cardState = cardData['state'] ?? '';
            scheduleState = cardData['schedule_state'] ?? false;
          });

          if(scheduleState){
            setState(() {
              from = cardData['from'] ?? '';
              _fromDateController.text=from;
              until = cardData['until'] ?? '';
              _untilDateController.text=until;
            });
          }

        } else {
          print('Dados do cartao vazios.');
        }
      }
    });
  }

  void _toggleCard(){
    setState(() {
      cardState = !cardState;
    });
  }

  void _toggleSchedule(){
    setState(() {
      scheduleState = !scheduleState;
    });
  }

  void _saveChanges() async {
    try {
      await databaseReference
          .child("houses")
          .child(houseId)
          .child("cards")
          .child(cardId)
          .update({
        'state': cardState,
        'schedule_state': scheduleState,
        'from' : from,
        'until' : until,

      });
      print("Card updated successfully!");
      Navigator.of(context).pop();
    } catch (error) {
      print("Something went wrong while updating a card");
      print(error);
    }
  }

  void _cancel(){
    Navigator.of(context).pop();
  }

  void _deleteCard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Card"),
          content: Text("Are you sure you want to delete the card '$cardId'?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                User? user = auth.currentUser;

                if (user != null) {
                  databaseReference.child("houses").child(houseId).child("cards").child(cardId).remove().then((_) {
                    setState(() {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                  });
                }
              },
              child: Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    this.cardId = args['cardId'];
    this.houseId = args['houseId'];
    print("cardId: " + cardId);
    print("houseId: " + houseId);

    if(!getCard) getCardInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text("Editing Card ${this.cardId}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.red,
            tooltip: 'delete',
            onPressed: () {
              _deleteCard();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Card Toggle"),
                Switch(
                    value: cardState,
                  onChanged: (bool val) {
                    _toggleCard();
                  },
                )
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Set Active Schedule"),
                Switch(
                  value: scheduleState,
                  onChanged: (bool val) {
                    _toggleSchedule();
                  },
                )
              ],
            ),
          ),

          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: scheduleState
                ? Container(
                    key: ValueKey<bool>(true),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 16.0),
                        Expanded(
                          child: TextField(
                            controller: _fromDateController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024, 05),
                                lastDate: DateTime(2028, 12),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _fromDateController.text =
                                      DateFormat('dd/MM/yyyy').format(pickedDate);
                                  this.from=_fromDateController.text;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'From',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ],
                    ),
                )
                : SizedBox.shrink(),
          ),

          //To text + calendar picker
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: scheduleState
                ? Container(
                  key: ValueKey<bool>(true),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 16.0),
                      Expanded(
                        child:
                        TextField(
                          controller: _untilDateController,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024, 05),
                              lastDate: DateTime(2028, 12),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _untilDateController.text =
                                    DateFormat('dd/MM/yyyy').format(pickedDate);
                                this.until=_untilDateController.text;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Until',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                        ),

                      ),
                    ],
                  ),
            )
                : SizedBox.shrink(),
          ),

          Spacer(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: (){
                    _cancel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text('Cancel',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:  (){
                    _saveChanges();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text('Save',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
