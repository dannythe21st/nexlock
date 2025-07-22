import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexlock/util/Drawer.dart';
import 'package:nexlock/House/Card.dart';
import 'package:nexlock/House/CardLock.dart';
import 'package:firebase_database/firebase_database.dart';


class HousePage extends StatefulWidget {
  @override
  _HousePageState createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool _sentryModeActivated = false;
  bool _lockActivated = false;
  late String houseId ="";
  late String houseName="";
  late String address="";
  bool getHouse = false;
  Map<String, Map<String, dynamic>> lockList = {};
  Map<String, Map<String, dynamic>> cardList = {};
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;


  @override
  void initState() {
    super.initState();
    print("listenToCard");
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      listenToCard();
    });
  }

  void listenToCard(){
    User? user = auth.currentUser;

    if (user != null) {
      databaseReference.child("houses").child(houseId).child("cards").onChildRemoved.listen((event){
        print('card removed: (value) ${event.snapshot.value}');
        print('card removed: (key) ${event.snapshot.key}');
        cardList.remove(event.snapshot.key);
        getHouseInfo();
      });

      databaseReference.child("houses").child(houseId).child("locks").onChildRemoved.listen((event){
        print('locks removed: (value) ${event.snapshot.value}');
        print('locks removed: (key) ${event.snapshot.key}');
        getHouseInfo();
      });

      databaseReference.child("houses").child(houseId).child("locks").onChildChanged.listen((event){
        print('locks changed: (key) ${event.snapshot.key}');
        getHouseInfo();
      });

      databaseReference.child("houses").child(houseId).child("cards").onChildChanged.listen((event){
        print('cards changed: (key) ${event.snapshot.key}');
        getHouseInfo();
      });

    }
  }


  void _toggleSentryModeActivation() {
    databaseReference
        .child("houses")
        .child(houseId)
        .child("sentryMode")
        .set(!_sentryModeActivated)
        .then((_) {
      setState(() {
        _sentryModeActivated = !_sentryModeActivated;
      });
    });
  }

  void _toggleLockActivation() {
    lockList.forEach((lockId, lockData) {
      try {
        databaseReference
            .child("houses")
            .child(houseId)
            .child("locks")
            .child(lockId)
            .update({
          'state': true,
        });
        print("Lock updated successfully!");
      } catch (error) {
        print("Something went wrong while updating a lock");
        print(error);
      }
    });
  }

  void getHouseInfo() {
    if (!mounted) return;
    getHouse = true;

    databaseReference
        .child("houses")
        .child(houseId)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (!mounted) return;
      if (snapshot.value is Map<dynamic, dynamic>) {
        // Extrai os dados da casa
        Map<dynamic, dynamic> houseData =
            snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            this.houseName = houseData['houseName'] ?? '';
            this.address = houseData['address'] ?? '';
            this._sentryModeActivated = houseData['sentryMode'] ?? false;
            this._lockActivated = houseData['locked'] ?? false;
          });

        if (houseData.isNotEmpty) {
          Map<dynamic, dynamic> locks = houseData['locks'] ?? {};
          locks.forEach((lockId, lockData) {
            setState(() {
              lockList[lockId] = lockData.cast<String, dynamic>();
            });
          });

          Map<dynamic, dynamic> cards = houseData['cards'] ?? {};
          cards.forEach((cardId, cardData) {
            setState(() {
              cardList[cardId] = cardData.cast<String, dynamic>();
            });
          });

        } else {
          print('Dados da casa estão vazios.');
        }
      } else {
        print('Os dados do snapshot não estão no formato esperado.');
      }
    });
  }

  void _addLockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController customController = TextEditingController();

        return AlertDialog(
          title: Text('Add Lock'),
          content: TextField(
            controller: customController,
            decoration: InputDecoration(hintText: "Lock ID"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addLock(customController.text.toString());
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addCardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController customController = TextEditingController();

        return AlertDialog(
          title: Text('Add Card'),
          content: TextField(
            controller: customController,
            decoration: InputDecoration(hintText: "Card ID"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addCard(customController.text.toString());
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addLock(String lockId) {
    User? user = auth.currentUser;

    if (user != null) {
      Map<String, dynamic> lockData = {
        'state': false,
      };

      databaseReference
          .child("houses")
          .child(houseId)
          .child("locks")
          .child(lockId)
          .set(lockData)
          .then((_) {
        setState(() {
          lockList[lockId] = lockData;
          print(lockList);
        });
      });
    }
  }

  void _addCard(String cardID) {
    User? user = auth.currentUser;

    if (user != null) {
      Map<String, dynamic> cardData = {
        'state': false,
        'schedule_state': false,
        'from': "16/05/2024",
        'until': "23/05/2024",
      };

      databaseReference
          .child("houses")
          .child(houseId)
          .child("cards")
          .child(cardID)
          .set(cardData)
          .then((_) {
        setState(() {
          cardList[cardID] = cardData;
          print(cardList);
        });
      });
    }
  }


  Future<String> isUidExists(String uid) async {
    String email = "-3";

    try {
      DatabaseEvent event = await databaseReference
          .child("users")
          .child(uid)
          .child("email")
          .once();

      DataSnapshot dataSnapshot = event.snapshot;

      if (dataSnapshot.value != null) {
        email = dataSnapshot.value.toString();
        print('Email associado ao UID $uid: $email');
      } else {
        print('UID $uid não encontrado');
        email = "-1";
      }
    } catch (e) {
      print('erro ao verificar o UID $uid: $e');
      email = "-2";
    }

    return email;
  }

  List<Map<String, String>> _users = [
    {'userId': '1', 'userName': 'User 1'},
    {'userId': '2', 'userName': 'User 2'},
    {'userId': '3', 'userName': 'User 3'},
  ];

  void _addAuthorizedUsers(String userId) async{
    String email = await isUidExists(userId);
    print(email);
    if(email!="-1"){
      print("UID exists: "+userId);
      User? user = auth.currentUser;

      if (user != null) {
        Map<String, dynamic> cardData = {
          'userName': email,
        };

        databaseReference
            .child("houses")
            .child(houseId)
            .child("authorizedUsers")
            .child(userId)
            .set(cardData)
            .then((_) {
          setState(() {
            _users.add({'userId': userId, 'userName': email});
          });
        });
      }

    }
    else{
      print("UID does not exist: "+userId);
    }
  }

  void _addAuthorizedUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController customController = TextEditingController();

        return AlertDialog(
          title: Text('Give permission to a new user'),
          content: TextField(
            controller: customController,
            decoration: InputDecoration(hintText: "UID"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addAuthorizedUsers(customController.text.toString());
              },
              child: Text('Confirm'),
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

    houseId = args['houseId'];
    print("houseId: " + houseId);

    if (!getHouse) getHouseInfo();

    return Scaffold(
      drawer: MyDrawer(currentPage: "House Page"),
      appBar: AppBar(
        title: Text(houseName),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                this.address,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "ID: "+this.houseId,
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: 30.0),
                child:
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Locks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.blue),
                              tooltip: "Add Lock",
                              onPressed: () {
                                _addLockDialog();
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "(tap to lock/unlock and long press to delete)",
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      ]
                    ),
              ),
              Container(
                height: 200,
                padding: EdgeInsets.all(20.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: lockList.length,
                  itemBuilder: (BuildContext context, int index) {
                    String lockId = lockList.keys.elementAt(index);
                    print("lock____Id:" + lockId);
                    Map<String, dynamic>? lockData = lockList[lockId];
                    if (lockData != null) {
                      bool lock_state = lockData['state'] ?? false;
                      return MyCardLock(lockId, lock_state,this.houseId);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: 30.0),
                child:
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Access Cards',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.blue),
                          tooltip: "Add Card",
                          onPressed: () {
                            _addCardDialog();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "(tap to edit and long press to delete)",
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ),
              Container(
                height: 200,
                padding: EdgeInsets.all(20.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cardList.length,
                  itemBuilder: (BuildContext context, int index) {
                    String cardId = cardList.keys.elementAt(index);
                    Map<String, dynamic> cardInfo = cardList[cardId]!;
                    bool state = cardInfo["state"];
                    print("card____Id:" + cardId);
                    return MyCard(cardId,this.houseId, state);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Padding(padding: EdgeInsets.only(right: 20.0),
                        child:
                        Column(
                          children: [
                            Text(
                              'Sentry Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _sentryModeActivated,
                              onChanged: (value) {
                                _toggleSentryModeActivation();
                              },
                            ),
                          ],
                        ),
                    ),

                    Column(
                      children: [
                        Text(
                          'Lock House',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _toggleLockActivation();
                          },
                          child: Text(
                              'Lock',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.all(20.0),
                  child:
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.only(right: 20.0),
                        child:
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/notifications',
                                  arguments: {'houseId':houseId});
                            },
                            child: Text('Events'),
                          ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/authusers',
                              arguments: {'houseId':houseId});
                        },
                        child: Text('Authorized Users'),
                      ),
                    ],
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row {
  _Row(this.userId, this.userName, this.context);

  final String userId;
  final String userName;
  final BuildContext context;

  IconButton get iconButton => IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$userName deleted'),
          ));
        },
      );
}

class _DataSource extends DataTableSource {
  _DataSource(this.context, this._data);

  final List<Map<String, String>>
      _data;
  final BuildContext context;
  int _selectedCount = 0;

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    final String userId = _data[index]['userId'] ?? 'Null_UserId';
    final String userName = _data[index]['userName'] ?? 'Null_userName';
    final _row = _Row(userId, userName, context);
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text('${_row.userId}')),
        DataCell(Text('${_row.userName}')),
        DataCell(_row.iconButton),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => _selectedCount;
}
