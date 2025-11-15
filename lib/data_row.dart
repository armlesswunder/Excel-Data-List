import 'package:excel_test/model/string_extension.dart';
import 'package:excel_test/utils.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'data_cell.dart';

class mDataRow {
  List<mDataCell> cells = [];

  Widget build({bool buildSortKey = true}) {
    if (getSortHeaderStr().contains('_group')) {
      return buildGroup(buildSortKey: buildSortKey);
    }
    return Row(
        children: cells.map((e) {
      if (!buildSortKey && !lazyBuild && e.cell == sortColumnIndex) {
        return _sizedContainer(Container(), e.getFlex());
      }
      if (e.row == 0) {
        return Container();
      }
      if (e.info) {
        return SizedBox(width: infoWidth + 24, child: e.build());
      }
      return _sizedContainer(e.build(), e.getFlex());
    }).toList());
  }

  Widget _sizedContainer(Widget child, int flex) {
    if (tableBuilder) {
      return SizedBox(width: flex * 10, child: child);
    } else {
      return Expanded(flex: flex, child: child);
    }
  }

  Widget buildGroup({bool buildSortKey = true}) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: cells.map((e) {
          if (!buildSortKey && !lazyBuild && e.cell == sortColumnIndex) {
            return Container();
          }
          return e.build();
        }).toList());
  }

  String getSortStr() {
    try {
      return cells[sortColumnIndex].getValue().trim().toLowerCase();
    } catch (e) {
      int row = cells.first.row;
      int cell = sortColumnIndex;
      mDataCell dataCell = getCell(row, cell);
      return dataCell.getValue().trim().toLowerCase();
    }
  }

  String getSortDisplayStr() {
    try {
      return cells[sortColumnIndex].getValue();
    } catch (e) {
      int row = cells.first.row;
      int cell = sortColumnIndex;
      mDataCell dataCell = getCell(row, cell);
      return dataCell.getValue();
    }
  }

  String getSearchStr() {
    try {
      return cells
          .map((e) => e.getValue())
          .reduce((value, element) => value + element);
    } catch (e) {
      int row = cells.first.row;
      int cell = sortColumnIndex;
      mDataCell dataCell = getCell(row, cell);
      return dataCell.getValue();
    }
  }

  bool isRowVisible(String searchStr) {
    try {
      if (checkedValue == 'Any') throw 'skipping';
      var cbIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_cb'));
      if (cbIndex != -1 && cbIndex != null) {
        var cell = cells[cbIndex];
        final value = cell.getValue().toLowerCase().trim();
        if (checkedValue == 'Checked' && value != '1') {
          return false;
        }
        if (checkedValue == 'Unchecked' && value == '1') {
          return false;
        }
      }
    } catch (e) {}

    try {
      if (favoriteValue == 'Any') throw 'skipping';
      var favIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_fav'));
      if (favIndex != -1 && favIndex != null) {
        var cell = cells[favIndex];
        final value = cell.getValue().toLowerCase().trim();
        if (favoriteValue == 'Favorite' && value != '1') {
          return false;
        }
        if (favoriteValue == 'Not Favorite' && value == '1') {
          return false;
        }
      }
    } catch (e) {}

    try {
      if (!useCurrentTime) throw 'skipping';
      var tfIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_timeframe'));
      if (tfIndex != -1 && tfIndex != null) {
        var cell = cells[tfIndex];
        final value = cell.getValue().toLowerCase().trim();
        var arr = value.split('-');
        var d1 = arr[0].getDate;
        print(d1);
        var d2 = arr[1].getDate;
        print(d2);
        return isInTimeframe(d1, d2);
      }
    } catch (e) {
      //print(e);
    }

    if (searchStr.isEmpty) return true;
    for (int i = 0; i < cells.length; i++) {
      try {
        var cell = cells[i];
        final value = cell.getValue().toLowerCase().trim();
        if (value.contains(searchStr.trim().toLowerCase())) {
          return true;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  String getSortHeaderStr() {
    try {
      return cells[sortColumnIndex].getHeader();
    } catch (e) {
      int row = cells.first.row;
      int cell = sortColumnIndex;
      mDataCell dataCell = getCell(row, cell);
      return dataCell.getHeader();
    }
  }

  mDataCell getCell(int rowIndex, int cellIndex) {
    var data = excel?.tables[table]?.rows[rowIndex][cellIndex];
    return mDataCell(row: rowIndex, cell: cellIndex, data: data);
  }
}
