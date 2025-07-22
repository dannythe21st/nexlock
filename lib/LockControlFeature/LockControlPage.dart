import 'package:flutter/material.dart';
import 'package:nexlock/util/Drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessRecord {
  final String time;
  final String user;
  final String action;

  AccessRecord({
    required this.time,
    required this.user,
    required this.action,
  });
}

class LockControlPage extends StatefulWidget {
  @override
  _LockControlPageState createState() => _LockControlPageState();
}

class _LockControlPageState extends State<LockControlPage> {
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    User? user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }


  bool _lockActivated = false;
  bool _sentryModeActivated = false;
  List<String> _usersWithAccess = ['Rafael', 'Daniel', 'Mike'];
  List<AccessRecord> _accessHistory = [
    AccessRecord(time: '10:00 AM', user: 'Rafael', action: 'Entrance'),
    AccessRecord(time: '11:30 AM', user: 'Daniel', action: 'Exit'),
    AccessRecord(time: '02:45 PM', user: 'Mike', action: 'Entrance'),
  ];

  void _toggleLockActivation() {
    setState(() {
      _lockActivated = !_lockActivated;
    });
  }

  void _toggleSentryModeActivation() {
    setState(() {
      _sentryModeActivated = !_sentryModeActivated;
    });
  }

  void _removeUserFromAccessList(String user) {
    setState(() {
      _usersWithAccess.remove(user);
    });
  }

  void _addUserToAccessList(String user) {
    setState(() {
      _usersWithAccess.add(user);
    });
  }

  void _showDeleteConfirmationDialog(String user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete $user?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _removeUserFromAccessList(user);
                Navigator.of(context).pop();
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showAddUserDialog() {
    String newUser = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add User"),
          content: TextField(
            onChanged: (value) {
              newUser = value;
            },
            decoration: InputDecoration(labelText: "Enter user name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newUser.isNotEmpty) {
                  _addUserToAccessList(newUser);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(currentPage: "Lock Control"),
      appBar: AppBar(
        title: Text('Lock Control'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          'Lock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _lockActivated,
                          onChanged: (value) {
                            _toggleLockActivation();
                          },
                        ),
                      ],
                    ),
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
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {

                            },
                            child: Text('Notifications'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {

                            },
                            child: Text('Open/Close remotely'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Users with Access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showAddUserDialog();
                      },
                      child: Text('Add User'),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _usersWithAccess.length,
                  itemBuilder: (BuildContext context, int index) {
                    final user = _usersWithAccess[index];
                    return ListTile(
                      title: Text(user),
                      trailing: IconButton(
                        icon: Icon(Icons.delete,color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.0),
                PaginatedDataTable(
                  header: Text('Access History'),
                  rowsPerPage: 5,
                  columns: [
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Action')),
                  ],
                  source: _accessDataSource(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataTableSource _accessDataSource() {
    return _AccessDataSource(_accessHistory);
  }
}

class _AccessDataSource extends DataTableSource {
  final List<AccessRecord> _accessHistory;

  _AccessDataSource(this._accessHistory);

  @override
  DataRow getRow(int index) {
    final record = _accessHistory[index];
    return DataRow(cells: [
      DataCell(Text(record.time)),
      DataCell(Text(record.user)),
      DataCell(Text(record.action)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _accessHistory.length;

  @override
  int get selectedRowCount => 0;
}
