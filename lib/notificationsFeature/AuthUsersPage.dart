import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthUsersPage extends StatefulWidget {
  @override
  _AuthUsersPageState createState() => _AuthUsersPageState();
}

class _AuthUsersPageState extends State<AuthUsersPage> {
  late String houseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic> args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    houseId = args['houseId'];
    print("houseId: $houseId");
  }

  void _showAddUserDialog() {
    TextEditingController userIdController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add user"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: InputDecoration(labelText: 'User ID:'),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nickname:'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String userId = userIdController.text;
                String name = nameController.text;

                Map<String, String> userData = {
                  'userId': userId,
                  'name': name,
                };

                DatabaseReference authUsersRef = FirebaseDatabase.instance
                    .ref()
                    .child('houses/$houseId/authusers')
                    .push();
                authUsersRef.set(userData);

                DatabaseReference userSharedHousesRef = FirebaseDatabase.instance
                    .ref()
                    .child('users/$userId/sharedHouses');
                userSharedHousesRef.child(houseId).set({
                  'houseName': houseId,
                });

                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveUserDialog(String userId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete user"),
          content: Text("Do you want to remove $name from the list (ID: $userId)?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _removeUser(userId);
                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _removeUser(String userId) {
    Query userQuery = FirebaseDatabase.instance
        .ref()
        .child('houses/$houseId/authusers')
        .orderByChild('userId')
        .equalTo(userId);

    userQuery.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          FirebaseDatabase.instance.ref().child('houses/$houseId/authusers/$key').remove();
        });
      }
    });

    DatabaseReference sharedHouseRef = FirebaseDatabase.instance
        .ref()
        .child('users/$userId/sharedHouses/$houseId');
    sharedHouseRef.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authorized Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: NotificationTable(
        houseId: houseId,
        onRemoveUser: _showRemoveUserDialog,
      ),
    );
  }
}

class NotificationTable extends StatefulWidget {
  final String houseId;
  final void Function(String userId, String name) onRemoveUser;

  NotificationTable({
    required this.houseId,
    required this.onRemoveUser,
  });

  @override
  _NotificationTableState createState() => _NotificationTableState();
}

class _NotificationTableState extends State<NotificationTable> {
  int _rowsPerPage = 10;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<Map<String, String>> _notifications = [];
  bool _isLoading = true;
  late DatabaseReference _notificationRef;
  late Stream<DatabaseEvent> _notificationStream;

  @override
  void initState() {
    super.initState();
    _notificationRef =
        FirebaseDatabase.instance.ref().child('houses/${widget.houseId}/authusers');
    _notificationStream = _notificationRef.onValue;
    _fetchNotifications();
  }

  void _fetchNotifications() {
    _notificationStream.listen((event) {
      if (!mounted) return;

      if (event.snapshot.value != null && event.snapshot.value is Map) {
        List<Map<String, String>> notifications = [];
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          Map<String, String> notification = {
            'name': value['name'],
            'userId': value['userId'],
          };
          notifications.add(notification);
        });

        notifications = notifications.reversed.toList();

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: PaginatedDataTable(
        header: Text(widget.houseId),
        rowsPerPage: _rowsPerPage,
        onRowsPerPageChanged: (value) {
          setState(() {
            _rowsPerPage = value!;
          });
        },
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('User ID')),
          DataColumn(label: Text('Actions')),
        ],
        source: NotificationDataSource(
          _notifications,
          onRemoveUser: widget.onRemoveUser,
        ),
      ),
    );
  }
}

class NotificationDataSource extends DataTableSource {
  final List<Map<String, String>> notifications;
  final void Function(String userId, String name) onRemoveUser;

  NotificationDataSource(this.notifications, {required this.onRemoveUser});

  @override
  DataRow getRow(int index) {
    final notification = notifications[index];
    return DataRow(cells: [
      DataCell(Text(notification['name']!)),
      DataCell(Text(notification['userId']!)),
      DataCell(
        IconButton(
          icon: Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () => onRemoveUser(notification['userId']!, notification['name']!),
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => notifications.length;

  @override
  int get selectedRowCount => 0;
}
