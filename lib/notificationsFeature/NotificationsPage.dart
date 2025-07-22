import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late String houseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic> args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    houseId = args['houseId'];
    print("houseId: $houseId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body: NotificationTable(houseId: houseId),
    );
  }
}

class NotificationTable extends StatefulWidget {
  final String houseId;

  NotificationTable({required this.houseId});

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
    _notificationRef = FirebaseDatabase.instance.ref().child('houses/${widget.houseId}/history');
    _notificationStream = _notificationRef.onValue;
    _fetchNotifications();
  }

  void _fetchNotifications() {
    _notificationStream.listen((event) {
      if (event.snapshot.value != null) {
        List<Map<String, String>> notifications = [];
        List<dynamic> data = event.snapshot.value as List<dynamic>;
        for (var item in data) {
          Map<String, String> notification = {
            'action': item['action'],
            'cardId': item['cardId'],
            'date': item['date'],
          };
          notifications.add(notification);
        }

        notifications = notifications.reversed.toList();

        setState(() {
          _notifications = notifications;
        });
      } else {
        setState(() {
          _notifications = [];
        });
      }
      setState(() {
        _isLoading = false;
      });
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
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Card ID')),
          DataColumn(
            label: Text('Date'),
            onSort: (columnIndex, ascending) {
              setState(() {
                _sortColumnIndex = columnIndex;
                _sortAscending = ascending;
              });
            },
          ),
        ],
        source: NotificationDataSource(_notifications),
      ),
    );
  }
}

class NotificationDataSource extends DataTableSource {
  final List<Map<String, String>> notifications;

  NotificationDataSource(this.notifications);

  @override
  DataRow getRow(int index) {
    final notification = notifications[index];
    return DataRow(cells: [
      DataCell(Text(
        notification['action']!,
        style: TextStyle(
          color: (notification['action'] == "close")? Colors.red : ((notification['action'] == "open")?Colors.green:Colors.blue),
        ),
      )),
      DataCell(Text(notification['cardId']!)),
      DataCell(Text(notification['date']!)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => notifications.length;

  @override
  int get selectedRowCount => 0;
}
