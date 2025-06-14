import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/common/app_theme.dart';

class AllItemPage extends StatefulWidget {
  final List<dynamic> itemList;
  final String itemType;
  final Future<bool> Function(int, List<dynamic>, String) confirmDeleteItem;
  final Future<void> Function(int, List<dynamic>, String) editItem;
  final void Function(int, List<dynamic>) deleteItem;
  final Widget Function(Map<String, String>, String) buildItem;

  AllItemPage({
    required this.itemList,
    required this.itemType,
    required this.confirmDeleteItem,
    required this.editItem,
    required this.deleteItem,
    required this.buildItem,
  });

  @override
  _AllItemPageState createState() => _AllItemPageState();
}

class _AllItemPageState extends State<AllItemPage> {
  late List<Map<String, String>> sortedItemList;

  @override
  void initState() {
    super.initState();
    _sortItemList();
  }

  void _sortItemList() {
    DateFormat dateFormat = DateFormat('MMMM d, yyyy');
    sortedItemList = List<Map<String, String>>.from(widget.itemList
      ..sort((a, b) => dateFormat.parse(b['date']!).compareTo(dateFormat.parse(a['date']!))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemType == 'medical history' ? 'All Medical History' : 'All Vaccination'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.005), // Add space between the title and the list
          Expanded(
            child: ListView.builder(
              itemCount: sortedItemList.length,
              itemBuilder: (context, index) {
                final entry = sortedItemList[index];
                int customIndex = widget.itemList.indexOf(entry);
                return Column(
                  children: [
                    Dismissible(
                      key: Key(entry['title']!),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          print('edit');
                          await widget.editItem(customIndex, widget.itemList, widget.itemType);
                          setState(() { _sortItemList();}); 
                          return false;
                        } else {
                          print('delete');
                          return await widget.confirmDeleteItem(customIndex, widget.itemList, widget.itemType);
                        }
                      },
                      background: Container(
                        color: Colors.grey,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 20),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: widget.buildItem(entry, widget.itemType),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01), // Add space between entries
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}