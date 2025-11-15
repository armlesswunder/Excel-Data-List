import 'package:excel/excel.dart';
import 'package:excel_test/theme.dart';
import 'package:flutter/material.dart';

import 'data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  TextEditingController searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(),
            body: Column(children: [
              Row(children: [_buildSearchbar()]),
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(children: _buildItems())))
            ])));
  }

  List<Widget> _buildItems() {
    List<Widget> tmp = [];

    var ss = '</SHEET_SEPARATOR/>';
    var vs = '</VALUE_SEPARATOR/>';

    List<String> values = [];
    var rows = excel?.tables[table]?.rows ?? [];
    var headers = rows[0];

    for (Sheet sheet in excel!.sheets.values) {
      for (int i = 0; i < sheet.rows.length; i++) {
        var r = sheet.rows[i];
        if (i == 0) continue;
        try {
          String displayValue = 'Sheet Name: ${sheet.sheetName}$ss';
          for (var cell in r) {
            if (cell != null && cell.value != null) {
              var header = headers[cell.columnIndex]?.value;
              var value = cell.value;
              displayValue += '$header: $value$vs';
            }
          }

          displayValue =
              displayValue.substring(0, displayValue.length - vs.length);
          values.add(displayValue);
          //print(displayValue);
        } catch (e) {
          print(e);
        }
      }
    }
    values.removeWhere((element) =>
        !element.toLowerCase().contains(searchCtrl.text.toLowerCase()));
    tmp.addAll(values.map((e) {
      var sheet = e.split(ss).first;
      var data = e.split(ss).last.split(vs);
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              ...data.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(e))),
              const Divider()
            ],
          ));
    }).toList());
    return tmp;
  }

  Widget _buildSearchbar() {
    return Expanded(
        child: TextField(
      style: TextStyle(color: darkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white24,
        hintText: 'Search',
        hintStyle: TextStyle(color: darkMode ? Colors.white : Colors.black),
        prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search,
              color: darkMode ? Colors.white : Colors.black,
            )),
        suffixIcon: IconButton(
          tooltip: 'Clear search',
          padding: const EdgeInsets.only(right: 16),
          onPressed: () => searchListClearPressed(),
          icon:
              Icon(Icons.clear, color: darkMode ? Colors.white : Colors.black),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48.0),
          borderSide: BorderSide.none,
        ),
      ),
      controller: searchCtrl,
      onChanged: (v) {
        setState(() {});
      },
    ));
  }

  void searchListClearPressed() {
    searchCtrl.text = '';
    setState(() {});
  }
}
