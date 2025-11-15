import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:excel_test/model/audit_data.dart';
import 'package:excel_test/prefs.dart';
import 'package:excel_test/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'data.dart';
import 'data_cell.dart';
import 'main.dart';

Future openFile(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: sheetsDir,
      type: FileType.custom,
      allowedExtensions: ['xlsx']);
  if (result != null) {
    if (Platform.isAndroid) {
      String? path = result.files.single.identifier;
      print(path);
      file = path?.replaceAll(
              'content://com.android.externalstorage.documents/document/primary%3AExcel%2Fsheets%2F',
              '$sheetsDir/') ??
          '';
      file = file.replaceAll('%2F', '/');
      var f = File(file);
      if (!f.existsSync()) {
        f.createSync();
        f.writeAsBytesSync(File(result.files.single.path!).readAsBytesSync());
      }
    } else {
      file = result.files.first.path!;
    }

    if (File(file).existsSync()) {
      setDefaultFile(file);
      assetDir = prefs.getString(assetDirKey(file)) ?? defaultAssetDir;
    }
    return;
  } else {
    // User canceled the picker
  }
}

DateTime getCurrentDate() {
  DateTime now = DateUtils.dateOnly(DateTime.now());
  DateTime n = DateTime(1970, now.month, now.day);
  return n;
}

DateTime getDate(DateTime date) {
  DateTime now = DateUtils.dateOnly(date);
  DateTime n = DateTime(1970, now.month, now.day);
  return n;
}

bool isInTimeframe(DateTime d1, DateTime d2) {
  if (d1.isAfter(d2)) {
    var d3 = d1.add(const Duration(days: 365));
    return (currentTime.isBefore(d2) || currentTime.isAtSameMomentAs(d2)) &&
        (d3.isAfter(currentTime) || d3.isAtSameMomentAs(currentTime));
  } else {
    return (d1.isBefore(currentTime) || d1.isAtSameMomentAs(currentTime)) &&
        (d2.isAfter(currentTime) || d2.isAtSameMomentAs(currentTime));
  }
}

Widget buildContainer(Widget child,
    {double ph = 8,
    double pv = 8,
    double mh = 8,
    double mv = 8,
    Color color = Colors.white10}) {
  return Container(
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(12))),
      margin: EdgeInsets.symmetric(horizontal: mh, vertical: mv),
      padding: EdgeInsets.symmetric(horizontal: ph, vertical: pv),
      child: child);
}

Future<void> showConfirmDialog(BuildContext context, Function callback,
    {String title = 'Confirm', String content = 'Are you sure?'}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              callback.call();
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showUpdateDialog(
    BuildContext context, Function callback, int cell, int row,
    {String title = 'Update', String content = 'Are you sure?'}) async {
  TextEditingController updateCtrl = TextEditingController();
  updateCtrl.text = content.trim();
  TextEditingController allCtrl = TextEditingController();

  var t = excel?.tables[table];
  var r = t?.row(row);
  var c = r![cell];
  mDataCell dataCell = mDataCell(row: row, cell: cell, data: c);
  bool usesChecks = dataCell.isCbData();
  bool usesFav = dataCell.isFavData();
  bool usesGroups = dataCell.isGroupData();
  int width = dataCell.getFlex();
  bool isImage = dataCell.isImage();
  bool isTimeframe = dataCell.isTimeframe();
  bool isPointerData = dataCell.isPointerData();
  String header = dataCell.getHeaderDisplay();
  String headerData = dataCell.getHeader();
  String sheetPtr = '';
  String colPtr = '';
  List<String> headers = [];
  if (isPointerData) {
    var args = headerData.replaceFirst('*', '');
    var arr = args.split(';');
    sheetPtr = arr[0];
    colPtr = arr[1];
    var rows = excel?.tables[sheetPtr]?.rows ?? [];
    var d = rows[0]
        .firstWhere((element) => element!.value.toString().contains(colPtr));
    //cell = rows[rowIndex][colIndex];

    headers = excel!.tables[sheetPtr]!.rows[0]
        .map((e) => e!.value.toString())
        .toList();
  }
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        content: StatefulBuilder(builder: (b, s) {
          return SingleChildScrollView(
              child: Column(children: [
            TextField(
              maxLines: null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              controller: updateCtrl,
              onSubmitted: (value) {
                Navigator.of(context).pop();
                var t = excel?.tables[table];
                var r = t?.row(row);
                var prev = '$table;$row;$cell;${r?[cell]?.value}';
                var change = '$table;$row;$cell;$value';
                var time = DateTime.now().microsecondsSinceEpoch;
                auditData.insert(0, AuditData('$time;;$prev;;$change'));
                print(change);
                setAuditData();
                if (Platform.isAndroid) {
                  unsavedChanges.add(change);
                  prefs.setStringList(fileContentsKey, unsavedChanges);
                }
                unsaved = true;
                callback.call(value);
              },
            ),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        showConfirmDialog(context, () {
                          excel!.sheets[table]?.removeColumn(cell);
                          saveExcel();
                          Navigator.pop(context);
                          mainState(() {});
                        }, title: 'Remove Column');
                      },
                      child: const Text('Remove Column',
                          style: TextStyle(color: Colors.red))),
                  TextButton(
                      onPressed: () {
                        showConfirmDialog(context, () {
                          excel!.sheets[table]?.removeRow(row);
                          saveExcel();
                          Navigator.pop(context);
                          mainState(() {});
                        }, title: 'Remove Row');
                      },
                      child: const Text('Remove Row',
                          style: TextStyle(color: Colors.red))),
                ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: allCtrl,
                ),
              ),
              TextButton(
                  onPressed: () {
                    showConfirmDialog(context, () {
                      int count = excel!.sheets[table]?.rows.length ?? 0;
                      for (int i = 0; i < count; i++) {
                        if (i == 0) continue;
                        var element = excel!.sheets[table]?.rows[i];
                        element![cell]?.value = TextCellValue(allCtrl.text);
                      }
                      saveExcel();
                      Navigator.pop(context);
                      mainState(() {});
                    }, title: 'Set All');
                  },
                  child: const Text('Set All',
                      style: TextStyle(color: Colors.green))),
            ]),
            const Divider(),
            Text('Cell Width:'),
            Slider(
              value: width.toDouble(),
              max: 50,
              min: 1,
              label: width.round().toString(),
              onChanged: (double value) {
                width = value.toInt();
                s(() {});
              },
            ),
            const Divider(),
            Wrap(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Checkbox data: '),
                Checkbox(
                    value: usesChecks,
                    onChanged: (v) {
                      usesChecks = !usesChecks;
                      s(() {});
                    })
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Favorite data: '),
                Checkbox(
                    value: usesFav,
                    onChanged: (v) {
                      usesFav = !usesFav;
                      s(() {});
                    })
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Group data: '),
                Checkbox(
                    value: usesGroups,
                    onChanged: (v) {
                      usesGroups = !usesGroups;
                      s(() {});
                    })
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Image data: '),
                Checkbox(
                    value: isImage,
                    onChanged: (v) {
                      isImage = !isImage;
                      s(() {});
                    })
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Timeframe data: '),
                Checkbox(
                    value: isTimeframe,
                    onChanged: (v) {
                      isTimeframe = !isTimeframe;
                      s(() {});
                    })
              ]),
            ]),
            const Divider(),
            if (sheetPtr.isNotEmpty)
              DropdownButton<String>(
                value: sheetPtr,
                elevation: 16,
                onChanged: (String? value) {
                  sheetPtr = value!;
                  headers = excel!.tables[sheetPtr]!.rows[0]
                      .map((e) => e!.value.toString())
                      .toList();
                  s(() {});
                  //initData();
                  //initTable();
                  //setState(() {});
                },
                items: sheets.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child:
                        Padding(padding: EdgeInsets.all(8), child: Text(value)),
                  );
                }).toList(),
              ),
            if (colPtr.isNotEmpty)
              DropdownButton<String>(
                value: colPtr,
                elevation: 16,
                onChanged: (String? value) {
                  colPtr = value!;
                  s(() {});
                  //initData();
                  //initTable();
                  //setState(() {});
                },
                items: headers.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child:
                        Padding(padding: EdgeInsets.all(8), child: Text(value)),
                  );
                }).toList(),
              ),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        showConfirmDialog(context, () {
                          int count = excel!.sheets[table]?.rows.length ?? 0;
                          for (int i = 0; i < count; i++) {
                            if (i == 0) continue;
                            var element = excel!.sheets[table]?.rows[i];
                            var leftVal =
                                element![cell - 1]?.value.toString() ?? '';
                            var rightVal =
                                element[cell]?.value.toString() ?? '';
                            element[cell - 1]?.value =
                                TextCellValue('$leftVal<sep>$rightVal');
                          }
                          saveExcel();
                          Navigator.pop(context);
                          mainState(() {});
                        }, title: 'Merge Left');
                      },
                      child: const Text('Merge Left',
                          style: TextStyle(color: Colors.green))),
                  TextButton(
                      onPressed: () {
                        showConfirmDialog(context, () {
                          int count = excel!.sheets[table]?.rows.length ?? 0;
                          for (int i = 0; i < count; i++) {
                            if (i == 0) continue;
                            var element = excel!.sheets[table]?.rows[i];
                            var leftVal =
                                element![cell]?.value.toString() ?? '';
                            var rightVal =
                                element[cell + 1]?.value.toString() ?? '';
                            element[cell + 1]?.value =
                                TextCellValue('$leftVal<sep>$rightVal');
                          }
                          saveExcel();
                          Navigator.pop(context);
                          mainState(() {});
                        }, title: 'Merge Right');
                      },
                      child: const Text('Merge Right',
                          style: TextStyle(color: Colors.green)))
                ]),
          ]));
        }),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              var t = excel?.tables[table];
              var r = t?.row(row);
              var prev = '$table;$row;$cell;${r?[cell]?.value}';
              var change = '$table;$row;$cell;${updateCtrl.text}';
              var time = DateTime.now().microsecondsSinceEpoch;
              auditData.insert(0, AuditData('$time;;$prev;;$change'));
              print(change);
              setAuditData();
              if (Platform.isAndroid) {
                unsavedChanges.add(change);
                prefs.setStringList(fileContentsKey, unsavedChanges);
              }
              unsaved = true;
              if (row == 0) {
                header = updateCtrl.text;
                if (header.contains('_')) {
                  header = header.split('_').first;
                }
              }
              if (usesChecks) {
                header += '_cb';
              }
              if (usesFav) {
                header += '_fav';
              }
              if (usesGroups) {
                header += '_group';
              }
              if (isImage) {
                header += '_img';
              }
              if (isTimeframe) {
                header += '_timeframe';
              }
              if (dataCell.getFlex() != width) {
                header += '_width=$width';
              }
              if (row == 0) {
                print(header);
                callback.call(header);
              } else {
                print(header);
                callback.call('${updateCtrl.text};;$header');
              }
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Dialog buildProgressDialog(BuildContext context, int count, int total) {
  return Dialog(
      //backgroundColor: darkMode ? dialogColor : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Progress',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              )),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text('$count/$total'),
                  const SizedBox(width: 8),
                  Expanded(
                      child: LinearProgressIndicator(
                    value: count / total,
                    backgroundColor: Colors.black45,
                  ))
                ],
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white70),
                  ),
                )),
          ),
          const SizedBox(height: 8)
        ],
      ));
}

List<Widget> buildDetails(int row) {
  List<Widget> temp = [];

  var s = excel?.tables[table]?.rows[row];
  var length = s?.length ?? 0;
  for (int i = 0; i < length; i++) {
    var element = s?[i];
    String header = '';

    try {
      var s = excel?.tables[table]?.rows[0][i]?.value;

      header = '$s';
      if (header == 'null') {
        continue;
      }
    } catch (e) {
      continue;
    }
    temp.add(Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('$header:'),
      if (element != null)
        mDataCell(
                row: element.rowIndex,
                cell: element.columnIndex,
                data: element.value)
            .build()
    ]));
  }

  return temp;
}

TextEditingController auditCtrl = TextEditingController();

List<AuditData> getAllAuditData() {
  if (auditCurrent) {
    return auditData;
  }
  List<AuditData> tmp = [];
  for (var sheet in sheets) {
    tmp.addAll(prefs
            .getStringList(auditKey(file, sheet))
            ?.map((e) => AuditData(e))
            .toList() ??
        []);
  }
  return tmp..sort((e1, e2) => e2.getTime().compareTo(e1.getTime()));
}

List<Widget> buildAudits(String txt) {
  List<Widget> temp = [];
  var arr = getAllAuditData();
  for (int i = 0; i < arr.length; i++) {
    var element = arr[i];
    var fromCell = element.getFromData();
    var toCell = element.getToData();
    var rowStr = fromCell.getRowStr();
    var header = fromCell.getHeader();
    if (header.toLowerCase().contains(txt.toLowerCase().trim()) ||
        rowStr.toLowerCase().contains(txt.toLowerCase().trim())) {
      temp.add(Column(children: [
        Text(
            '${getAuditTimestamp(element.getTime())}: ${auditCurrent ? '' : element.getSheet()}: $rowStr:'),
        Row(children: [
          Text('$header:'),
          fromCell.build(),
          Text('=>'),
          toCell.build(),
        ])
      ]));
    }
  }

  return temp;
}

bool auditCurrent = true;

Future<void> showAuditDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Text('Audit current: '),
              Checkbox(
                  value: auditCurrent,
                  onChanged: (b) {
                    auditCurrent = !auditCurrent;
                    setState(() {});
                  })
            ],
          ),
          content: SingleChildScrollView(
              child: Column(children: [
            TextField(
              style: TextStyle(color: darkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                hintText: 'Search',
                hintStyle:
                    TextStyle(color: darkMode ? Colors.white : Colors.black),
                prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.search,
                      color: darkMode ? Colors.white : Colors.black,
                    )),
                suffixIcon: IconButton(
                  padding: const EdgeInsets.only(right: 16),
                  onPressed: () {
                    auditCtrl.text = '';
                    setState(() {});
                  },
                  icon: Icon(Icons.clear,
                      color: darkMode ? Colors.white : Colors.black),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(48.0),
                  borderSide: BorderSide.none,
                ),
              ),
              controller: auditCtrl,
              onChanged: (v) {
                setState(() {});
              },
            ),
            ...buildAudits(auditCtrl.text)
          ])),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
    },
  );
}

Future<void> showInfoDialog(BuildContext context, int row,
    {String title = 'Info'}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        content: SingleChildScrollView(
            child: Column(children: [...buildDetails(row)])),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showSaveDialog(BuildContext context,
    {String title = 'There was an error saving'}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        actions: <Widget>[
          TextButton(
            child: const Text('Try again'),
            onPressed: () async {
              try {
                File(file)
                    .writeAsBytes(excel!.encode()!)
                    .then((value) => Navigator.of(context).pop());
              } catch (e) {
                await showSaveDialog(context,
                        title: 'There was an error saving the file.')
                    .then((value) => Navigator.of(context).pop());
              }
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

int fileSize = 0;

bool isLargeFile() {
  return fileSize > 100000;
}

/// check if the string contains only numbers
bool isNumber(String str) {
  RegExp _numeric = RegExp(r'^-?[0-9]+$');
  return _numeric.hasMatch(str);
}

String getFileName(String file, {bool extension = false}) {
  var arr = file.split(Platform.pathSeparator);
  var name = arr[arr.length - 1];
  if (!extension && name.contains('.')) {
    name = name.substring(0, name.lastIndexOf('.'));
  }
  return name;
}

String getFileTimestamp(DateTime time) {
  var formatter = DateFormat('yyyyMMdd_HHmmss');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

String getAuditTimestamp(DateTime time) {
  var formatter = DateFormat('MM/dd/yyyy hh:mm:ss');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

void cleanupFiles() async {
  var appDir = Directory(sheetsDir).parent;
  if (Platform.isAndroid) {
    appDir.listSync().forEach((element) {
      var f = File(element.path);
      if (f.existsSync() &&
          f.path.endsWith('.zip') &&
          f.path.contains('excel_backup')) {
        f.deleteSync();
      }
    });
  }
}

void exportAllFiles() async {
  var appDir = Directory(sheetsDir).parent;
  if (Platform.isAndroid) {
    var encoder = ZipFileEncoder();
    String zipPath =
        '${appDir.path}${Platform.pathSeparator}excel_backup${getFileTimestamp(DateTime.now())}.zip';
    print(zipPath);
    encoder.create(zipPath);
    appDir.listSync().forEach((e) {
      if (File(e.path).existsSync()) {
        encoder.addFile(File(e.path));
      } else {
        encoder.addDirectory(Directory(e.path));
      }
    });
    //encoder.addDirectory(Directory(playlistDir));
    encoder.close();
    XFile xfile = XFile(zipPath);
    await Share.shareXFiles([xfile], text: 'Export Data');
  }
}

void initData() {
  try {
    var f = File(file);
    if (f.existsSync()) {
      var bytes = f.readAsBytesSync();
      fileSize = bytes.length;
      excel = Excel.decodeBytes(bytes);
      print('Sheet Size=$fileSize');
      sheets = excel!.tables.keys.toList();
      table = excel!.getDefaultSheet() ?? sheets[0];
      sheetIndex = sheets.indexWhere((element) => element == table);
      getSheetSettings();
    }
  } catch (e) {
    showErrorDialog('File error: $e');
  }
}

void initTable() {
  table = excel!.getDefaultSheet() ?? sheets[0];
  sheetIndex = sheets.indexWhere((element) => element == table);
  getSheetSettings();
}

void nextSheet() {
  var keys = excel!.sheets.keys.toList();
  var index = keys.indexWhere((element) => element == table);
  index += 1;
  if (index >= keys.length) {
    index = 0;
  }
  table = keys[index];
  sheetIndex = sheets.indexOf(table!);
  var b = excel!.setDefaultSheet(sheets[sheetIndex]);
  if (b) {
    //File(file).writeAsBytesSync(excel!.encode()!);
  }
  initTable();
  mainState(() {});
}

void prevSheet() {
  var keys = excel!.sheets.keys.toList();
  var index = keys.indexWhere((element) => element == table);
  if (index == 0) {
    index = keys.length - 1;
  } else {
    index -= 1;
  }
  table = keys[index];
  sheetIndex = sheets.indexOf(table!);
  var b = excel!.setDefaultSheet(sheets[sheetIndex]);
  if (b) {
    //File(file).writeAsBytesSync(excel!.encode()!);
  }
  initTable();
  mainState(() {});
}

void chooseFilePressed(BuildContext context) async {
  await openFile(context);
  initData();
  mainState(() {});
}
