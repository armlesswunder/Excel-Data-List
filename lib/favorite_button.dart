import 'dart:io';

import 'package:excel/excel.dart';
import 'package:excel_test/prefs.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'model/audit_data.dart';

class FavoriteButton extends StatefulWidget {
  final int row;
  final int cell;
  final String sheet;
  const FavoriteButton(
      {super.key, required this.row, required this.cell, required this.sheet});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: IconButton(
      onPressed: () {
        setSelected(!isSelected());
      },
      icon: Icon(
        isSelected() ? Icons.favorite : Icons.favorite_border,
        color: Colors.red.shade300,
      ),
    ));
  }

  bool isSelected() {
    var t = excel?.tables[widget.sheet];
    var r = t?.row(widget.row);
    var c = r?[widget.cell]?.value.toString();
    return c == "1";
  }

  void setSelected(bool selected) {
    var t = excel?.tables[widget.sheet];
    var r = t?.row(widget.row);
    r?[widget.cell]?.value = TextCellValue(selected ? '1' : '0');
    var prev = '${widget.sheet};${widget.row};${widget.cell};${!selected}';
    var change = '${widget.sheet};${widget.row};${widget.cell};$selected';
    var time = DateTime.now().microsecondsSinceEpoch;
    auditData.insert(0, AuditData('$time;;$prev;;$change'));
    print(change);

    if (Platform.isAndroid) {
      unsavedChanges.add(change);
      prefs.setStringList(fileContentsKey, unsavedChanges);
    }
    setAuditData();
    unsaved = true;
    try {
      //saveExcel();
      mainState(() {});
      saveBtnState(() {});
    } catch (e) {}
  }
}
