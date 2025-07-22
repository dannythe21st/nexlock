import 'package:flutter/material.dart';
import 'package:nexlock/util/Drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String,String> houses = {}; // <houseId,houseName>
  Map<String,String> sharedHouses = {};


  @override
  void initState() {
    super.initState();
    listenToHouses();
  }

  void userSignOut() async {
    await FirebaseAuth.instance.signOut();
  }


  void listenToHouses(){
    User? user = auth.currentUser;

    if (user != null) {
      databaseReference.child("users").child(user.uid).child("houses").onChildAdded.listen((event){
        print('Casa adicionada: ${event.snapshot.value}');
        getHouses();
      });

      databaseReference.child("users").child(user.uid).child("sharedHouses").onChildAdded.listen((event){
        print('shared house adicionada: ${event.snapshot.value}');
        getSharedHouses();
      });
    }
  }


  // Método para adicionar uma nova casa
  void _addHouse(String houseName,String address) {
    User? user = auth.currentUser;

    if (user != null) {
      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String houseId = houseName + timeStamp;

      databaseReference.child("users").child(user.uid).child("houses").child(houseId).set({
        'houseName': houseName,
      }).then((_) {
        setState(() {
          houses[houseId] = houseName;
        });
      });

      // Adiciona a casa globalmente
      databaseReference.child("houses").child(houseId).set({
        'houseName': houseName,
        'address': address,
        'sentryMode': false,
        'locked': false,
      });
    }
  }


  void _addHouseDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController NameController = TextEditingController();
        TextEditingController AddressController = TextEditingController();

        return AlertDialog(
          title: Text('Add house'),
          content:Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: NameController,
                decoration: InputDecoration(hintText: "Name"),
              ),
              TextField(
                controller: AddressController,
                decoration: InputDecoration(hintText: "Address"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if(NameController.text.toString()!="" &&  AddressController.text.toString()!=""){
                  Navigator.of(context).pop();
                  _addHouse(NameController.text.toString(),AddressController.text.toString());
                }

              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Método para remover uma casa
  void _removeHouse(String houseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to delete the house '$houseId'?"),
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
                  // Remove a casa do nó do user
                  databaseReference.child("users").child(user.uid).child("houses").child(houseId).remove().then((_) {
                    setState(() {
                      houses.remove(houseId);
                      Navigator.of(context).pop();
                    });
                  });

                  // Remove a casa do nó global "houses"
                  databaseReference.child("houses").child(houseId).remove();
                }
              },
              child: Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Log out"),
          content: Text("Do you want to log out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                userSignOut();
                // Limpa o histórico de navegação e retorna para a página de login
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }

  // Método para obter as casas do user
  void getHouses() async {
    User? user = auth.currentUser;

    if (user != null) {
      databaseReference.child("users").child(user.uid).child("houses").once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value is Map) {
          Map<dynamic, dynamic> housesSnapshot = snapshot.value as Map<dynamic, dynamic>;
          Map<String, String> houses = {};

          housesSnapshot.forEach((houseId, houseData) {
            String houseName = houseData['houseName'];
            houses[houseId] = houseName;
          });

          setState(() {
            this.houses = houses;
          });
          print(this.houses);
        }
      });
    }
  }

  void getSharedHouses() async {
    User? user = auth.currentUser;

    if (user != null) {
      databaseReference.child("users").child(user.uid).child("sharedHouses").once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value is Map) {
          Map<dynamic, dynamic> housesSnapshot = snapshot.value as Map<dynamic, dynamic>;
          Map<String, String> sharedHouses = {};

          housesSnapshot.forEach((houseId, houseData) {
            String houseName = houseData['houseName'];
            sharedHouses[houseId] = houseName;
          });

          setState(() {
            this.sharedHouses = sharedHouses;
          });
          print(this.sharedHouses);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(currentPage: "Home",),
      appBar: AppBar(
        title: Text("NexLock"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.red,
            tooltip: 'Logout',
            onPressed: () {
              _logoutDialog();
            },
          ),
        ],
      ),
      body:
      SingleChildScrollView(
      child:
        Column(
          children: [
            Text(
              "My Houses",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 400,
              child: ListView.builder(
                itemCount: houses.length,
                itemBuilder: (context, index) {
                  String key = houses.keys.elementAt(index);
                  return ListTile(
                    title: Text('${houses[key]}'),
                    subtitle: Text('Id: $key'),
                    onTap: () {
                      Navigator.pushNamed(context, '/house',
                          arguments: {'houseId':key});
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.orange),
                          tooltip: 'More',
                          onPressed: () {
                            Navigator.pushNamed(context, '/house',
                                arguments: {'houseId':key});
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () {
                            _removeHouse(key);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              "Rented Houses",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 400,
              child: ListView.builder(
                itemCount: sharedHouses.length,
                itemBuilder: (context, index) {
                  String key = sharedHouses.keys.elementAt(index);
                  return ListTile(
                    title: Text('${sharedHouses[key]}'),
                    subtitle: Text('Id: $key'),
                    onTap: () {
                      Navigator.pushNamed(context, '/sharedhouse',
                          arguments: {'houseId':key});
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.orange),
                          tooltip: 'more',
                          onPressed: () {
                            Navigator.pushNamed(context, '/sharedhouse',
                                arguments: {'houseId':key});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addHouseDialog();
        },
        tooltip: 'Add House',
        child: Icon(Icons.add),
      ),
    );
  }
}
