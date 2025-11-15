import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:excel/excel.dart';
import 'package:excel_test/abw_file_picker/page.dart';
import 'package:excel_test/model/string_extension.dart';
import 'package:excel_test/prefs.dart';
import 'package:excel_test/search_page.dart';
import 'package:excel_test/settings.dart';
import 'package:excel_test/theme.dart';
import 'package:excel_test/utils.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'data_cell.dart';
import 'data_row.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      title: 'Flutter Demo',
      theme: darkTheme,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  TextEditingController searchCtrl = TextEditingController();
  final _controller1 = ScrollController();
  final _controller2 = ScrollController();

  num lastHotkeyPress = 0;

  void _onKey(RawKeyEvent event) {
    bool keyEventHandled = false;
    num currentTime = DateTime.now().millisecondsSinceEpoch;
    num timeDifference = currentTime - lastHotkeyPress;
    if (timeDifference < 200) return;
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      searchFocus.requestFocus();
      keyEventHandled = true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
      saveExcel();
      setState(() {});
      keyEventHandled = true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyO) {
      chooseFilePressed(context);
      keyEventHandled = true;
    }
    if (event.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      prevSheet();
      keyEventHandled = true;
    }
    if (event.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      nextSheet();
      keyEventHandled = true;
    }
    if (keyEventHandled) {
      lastHotkeyPress = currentTime;
    }
  }

  late FocusNode _optionsFocusNode;

  Widget _buildOptionsPopup() {
    return MenuAnchor(
      childFocusNode: _optionsFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () async {
            await openFile(context);
            initData();
            setState(() {});
          },
          child: const Text('Open File'),
        ),
        MenuItemButton(
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return const ABWFilePickerPage();
              },
            ));
          },
          child: const Text('Select File'),
        ),
        MenuItemButton(
          onPressed: () async {
            showConfirmDialog(context, () {
              var headerRow = excel!.sheets[table]?.rows[0];
              var dataRows = List.of(excel!.sheets[table]!.rows
                  .sublist(1, excel!.sheets[table]!.rows.length));
              dataRows.shuffle();
              dataRows.insert(0, headerRow!);

              int i = 0;
              List<List<String>> l = dataRows
                  .map((e) => e.map((e) => e!.value.toString()).toList())
                  .toList();
              for (var row in l) {
                for (int j = 0; j < excel!.sheets[table]!.rows[i].length; j++) {
                  var t = excel!.tables[table];
                  var r = t?.row(i);
                  r?[j]?.value = TextCellValue(row[j] == 'null' ? '' : row[j]);
                }
                i += 1;
              }

              saveExcel();
              initData();
              setState(() {});
              mainState(() {});
            });
          },
          child: const Text('Shuffle'),
        ),
        MenuItemButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return const SettingsPage();
              },
            ));
          },
          child: const Text('Settings'),
        ),
        MenuItemButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return const SearchPage();
              },
            ));
          },
          child: const Text('Find in Tables'),
        ),
        MenuItemButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => buildProgressDialog(
                    context, getTotal() - getCount(), getTotal()));
          },
          child: const Text('Progress'),
        ),
        SubmenuButton(menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () {
              checkedValue = checkedChoices[0];
              prefs.setString(
                  checkedFilterKey(file, sheets[sheetIndex]), checkedValue);
              setState(() {});
            },
            child: Text(checkedChoices[0]),
          ),
          MenuItemButton(
            onPressed: () {
              checkedValue = checkedChoices[1];
              prefs.setString(
                  checkedFilterKey(file, sheets[sheetIndex]), checkedValue);
              setState(() {});
            },
            child: Text(checkedChoices[1]),
          ),
          MenuItemButton(
            onPressed: () {
              checkedValue = checkedChoices[2];
              prefs.setString(
                  checkedFilterKey(file, sheets[sheetIndex]), checkedValue);
              setState(() {});
            },
            child: Text(checkedChoices[2]),
          ),
        ], child: const Text('Checked Filter'))
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          visualDensity: VisualDensity.compact,
          focusNode: _optionsFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  bool rowVisible(List<Data?> row) {
    //check checked s
    try {
      if (checkedValue == 'Any') throw 'skipping';
      var cbIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_cb'));
      if (cbIndex != -1 && cbIndex != null) {
        var cell = row[cbIndex];
        if (cell != null) {
          final value = '${cell.value}'.toLowerCase().trim();
          if (checkedValue == 'Checked' && value != '1') {
            return false;
          }
          if (checkedValue == 'Unchecked' && value == '1') {
            return false;
          }
        }
      }
    } catch (e) {}

    try {
      if (favoriteValue == 'Any') throw 'skipping';
      var favIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_fav'));
      if (favIndex != -1 && favIndex != null) {
        var cell = row[favIndex];
        if (cell != null) {
          final value = '${cell.value}'.toLowerCase().trim();
          if (favoriteValue == 'Favorite' && value != '1') {
            return false;
          }
          if (favoriteValue == 'Not Favorite' && value == '1') {
            return false;
          }
        }
      }
    } catch (e) {}

    try {
      if (!useCurrentTime) throw 'skipping';
      var tfIndex = excel?.tables[table]?.rows[0]
          .indexWhere((element) => '${element?.value}'.contains('_timeframe'));
      if (tfIndex != -1 && tfIndex != null) {
        var cell = row[tfIndex];
        if (cell != null) {
          final value = '${cell.value}'.toLowerCase().trim();
          var arr = value.split('-');
          var d1 = arr[0].getDate;
          print(d1);
          var d2 = arr[1].getDate;
          print(d2);
          return isInTimeframe(d1, d2);
        }
      }
    } catch (e) {
      //print(e);
    }

    if (searchCtrl.text.isEmpty) return true;
    for (int i = 0; i < row.length; i++) {
      try {
        var cell = row[i];
        if (cell == null) continue;
        final value = '${cell.value}'.toLowerCase().trim();
        if (value.contains(searchCtrl.text.trim().toLowerCase())) {
          return true;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Widget buildCount(int count) {
    return Text('Count: ${getCount()}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60));
  }

  int getCount() {
    var count = rowCount;
    try {
      var rows = List.of(excel!.tables[table]!.rows);
      rows.removeAt(0);
      var sub = rows.map((List<Data?> dataList) {
        var sl = dataList.map((d) {
          if (d == null) {
            return mDataCell(row: -1, cell: -1, data: '');
          }
          return mDataCell(row: d.rowIndex, cell: d.columnIndex, data: d.value);
        }).toList();
        var r = mDataRow();
        r.cells.addAll(sl);
        return r;
      }).toList();
      sub = sub
          .where((element) =>
              element.isRowVisible(searchCtrl.text.trim().toLowerCase()))
          .toList();
      count = sub.length;
    } catch (e) {}
    return count;
  }

  int getTotal() {
    var count = rowCount;
    try {
      var rows = List.of(excel!.tables[table]!.rows);
      rows.removeAt(0);
      count = rows.length;
    } catch (e) {}
    return count;
  }

  Widget buildHeader() {
    if (file.isEmpty || sheets.isEmpty) return Container();

    var rows = excel?.tables[table]?.rows ?? [];
    rowCount = rows.length;

    var row = rows[0];
    List<Widget> rowWidgets = [];

    for (int i = 0; i < row.length; i++) {
      var cell = row[i];
      if (cell == null || cell.value == null) break;
      final value = cell.value;

      var mc = tableBuilder ? maxColumns - 1 : maxColumns;
      if (i >= mc) {
        if (i == mc) {
          var e = mDataCell(
              row: cell.rowIndex,
              cell: cell.columnIndex,
              data: value,
              info: true);
          rowWidgets.add(e.buildHeader());
        }
        break;
      }

      var e =
          mDataCell(row: cell.rowIndex, cell: cell.columnIndex, data: value);
      Widget child = tableBuilder
          ? SizedBox(width: e.getFlex() * 10, child: e.buildHeader())
          : Expanded(flex: e.getFlex(), child: e.buildHeader());
      rowWidgets.add(child);

      if (tableBuilder && row.length == i + 1) {
        var e = mDataCell(
            row: cell.rowIndex,
            cell: cell.columnIndex,
            data: value,
            info: true);
        rowWidgets.add(e.buildHeader());
      }
    }
    columnCount = rowWidgets.length;
    return Row(children: rowWidgets);
  }

  bool specialHeaderData(String? str) {
    if (str == null) return true;
    return str.contains('_cb') || str.contains('_fav');
  }

  List<mDataRow> allRows = [];
  List<Widget> getData(BuildContext context) {
    if (file.isEmpty || !File(file).existsSync()) return [Container()];
    allRows = [];
    var rows = excel?.tables[table]?.rows ?? [];
    String sortHeader = rows[0][sortColumnIndex]!.value.toString();
    for (int j = 0; j < rows.length; j++) {
      var row = rows[j];
      mDataRow dataRow = mDataRow();
      if (j == 0 || !rowVisible(row)) {
        continue;
      }

      for (int i = 0; i < row.length; i++) {
        var cell = row[i];
        bool pointerData = false;
        String sheetPtr = table!;
        int colIndex = cell?.columnIndex ?? 0;
        int rowIndex = cell?.rowIndex ?? 0;
        Data? header;
        try {
          header = excel?.sheets[table]?.rows.first[i];
          if (header == null || header.value == null) {
            continue;
          }
          if (header.value.toString().startsWith('*')) {
            pointerData = true;
            var args = header.value.toString().replaceFirst('*', '');
            var arr = args.split(';');
            sheetPtr = arr[0];
            String colPtr = arr[1];
            var rows = excel?.tables[sheetPtr]?.rows ?? [];
            header = rows[0].firstWhere(
                (element) => element!.value.toString().contains(colPtr));
            colIndex = rows[0].indexWhere((e) => e!.value.toString() == colPtr);
            try {
              rowIndex = int.parse(cell!.value.toString());
            } catch (e) {
              rowIndex = j;
            }
            cell = rows[rowIndex][colIndex];
          }
          if (header?.value != null && cell == null) {
            row[i] = Data.newData(excel!.sheets[table]!, j, i);
            cell = row[i];
            cell!.value = TextCellValue('');
          }
        } catch (e) {}
        if (cell == null) {
          print('Null cell');
          dataRow.cells.add(mDataCell(row: j, cell: i, data: 'null'));
          continue;
        }
        final value = cell.value;

        if (i >= maxColumns) {
          if (i == maxColumns) {
            dataRow.cells.add(mDataCell(
                row: cell.rowIndex,
                cell: cell.columnIndex,
                data: value,
                info: true));
          }
          break;
        }

        if (pointerData) {
          dataRow.cells.add(mDataCell(
              row: rowIndex, cell: colIndex, data: value, sheet: sheetPtr));
        } else {
          dataRow.cells.add(mDataCell(
              row: cell.rowIndex, cell: cell.columnIndex, data: value));
        }
        if (tableBuilder && row.length == i + 1) {
          dataRow.cells.add(mDataCell(
              row: cell.rowIndex,
              cell: cell.columnIndex,
              data: value,
              info: true));
        }
      }
      allRows.add(dataRow);
    }

    if (!ignoreSort) {
      allRows.sort((a, b) {
        var aVal = a.getSortStr();
        var bVal = b.getSortStr();

        if (isNumber(aVal) && isNumber(bVal)) {
          try {
            return int.parse(aVal).compareTo(int.parse(bVal));
          } catch (e) {}
        }

        return a.getSortStr().compareTo(b.getSortStr());
      });
      if (sortColumnMode == 1) {
        allRows = allRows.reversed.toList();
      }
    }

    if (!sortHeader.contains('_cb')) {
      Map<String, List<mDataRow>> map = {};
      for (var element in allRows) {
        var key = element.getSortStr();
        if (!map.containsKey(key)) {
          map[key] = [];
        }
        map[key]?.add(element);
      }

      List<Widget> tmp = [];
      bool useWrap = false;
      map.forEach((key, value) {
        List<Widget> tmp2 = [];
        for (int i = 0; i < value.length; i++) {
          var element = value[i];
          if (element.getSortHeaderStr().contains('_group')) useWrap = true;
          tmp2.add(element.build(buildSortKey: i == 0));
        }
        //tmp.add(Text(key));
        tmp.add(Container(
          color: Colors.white10,
          child: useWrap
              ? Wrap(
                  children: tmp2,
                )
              : Column(
                  children: tmp2,
                ),
        ));
        tmp.add(const SizedBox(
          height: 16,
        ));
      });

      return tmp;
    } else {
      return allRows.map((e) => e.build()).toList();
    }
  }

  bool bh = false;

  Widget buildRow(BuildContext context, int pos, List<List<Data?>> rows) {
    if (file.isEmpty) return Container();

    if (pos >= rows.length) return Container();
    var row = rows[pos];
    mDataRow dataRow = mDataRow();
    if (!rowVisible(row)) {
      return Container();
    }

    for (int i = 0; i < row.length; i++) {
      var cell = row[i];

      try {
        var header = excel?.sheets[table]?.rows.first[i];
        if (header == null || header.value == null) {
          continue;
        } else if (header.value != null && cell == null) {
          row[i] = Data.newData(excel!.sheets[table]!, pos, i);
          cell = row[i];
          cell!.value = TextCellValue('');
        }
      } catch (e) {}
      if (cell == null) {
        dataRow.cells.add(mDataCell(row: -1, cell: -1, data: 'null'));
        continue;
      }
      final value = cell.value;

      if (i >= maxColumns) {
        if (i == maxColumns) {
          dataRow.cells.add(mDataCell(
              row: cell.rowIndex,
              cell: cell.columnIndex,
              data: value,
              info: true));
        }
        break;
      }

      dataRow.cells.add(
          mDataCell(row: cell.rowIndex, cell: cell.columnIndex, data: value));
      if (tableBuilder && row.length == i + 1) {
        dataRow.cells.add(mDataCell(
            row: cell.rowIndex,
            cell: cell.columnIndex,
            data: value,
            info: true));
      }
    }
    return dataRow.build();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('ABW: App Resumed');
        break;
      case AppLifecycleState.paused:
        //Execute the code the when user leave the app
        if (!Platform.isWindows) {
          isPaused = true;
          //excel!.save();
          print('ABW: App Paused');
          try {
            //File(file).writeAsBytesSync(excel!.encode()!);
            //unsaved = false;
          } catch (e) {
            showErrorDialog('There was an error saving the file.');
          }
          break;
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller1.removeListener(listener1);
    _controller2.removeListener(listener2);
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  bool isDraggingHeader = false;

  var _flag1 = false;
  var _flag2 = false;

  void listener1() {
    if (_flag2) return;
    _flag1 = true;
    _controller2.jumpTo(_controller1.offset);
    _flag1 = false;
  }

  void listener2() {
    if (_flag1) return;
    _flag2 = true;
    _controller1.jumpTo(_controller2.offset);
    _flag2 = false;
  }

  @override
  void initState() {
    super.initState();
    _optionsFocusNode = FocusNode();
    _controller1.addListener(listener1);
    _controller2.addListener(listener2);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black87,
    ));

    WidgetsBinding.instance.addObserver(this);

    if (Platform.isWindows) {
      getApplicationDocumentsDirectory().then((value) {
        assetDir =
            '${value.path}${Platform.pathSeparator}excel_data${Platform.pathSeparator}assets';
        defaultAssetDir = assetDir;
        sheetsDir =
            '${value.path}${Platform.pathSeparator}excel_data${Platform.pathSeparator}sheets';
        cacheDir =
            '${value.path}${Platform.pathSeparator}excel_data${Platform.pathSeparator}cache';
        if (!Directory(assetDir).existsSync()) {
          Directory(assetDir).createSync(recursive: true);
        }
        if (!Directory(sheetsDir).existsSync()) {
          Directory(sheetsDir).createSync(recursive: true);
        }
        if (!Directory(cacheDir).existsSync()) {
          Directory(cacheDir).createSync(recursive: true);
        }
      });

      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        if (unsaved) {
          await File(file)
              .writeAsBytes(excel!.encode()!)
              .catchError((err) async {
            await showSaveDialog(context);
            return File('');
          });
        }

        return true;
      });
    }
    if (Platform.isAndroid) {
      requestPermissions();

      //getExternalStorageDirectory().then((value) {

      var value = Directory('/storage/emulated/0/Excel/');
      if (!value.existsSync()) {
        value.createSync();
      }
      assetDir = '${value.path}assets';
      defaultAssetDir = assetDir;
      sheetsDir = '${value.path}sheets';
      cacheDir = '${value.path}cache';
      if (!Directory(assetDir).existsSync()) {
        Directory(assetDir).createSync();
      }
      if (!Directory(sheetsDir).existsSync()) {
        Directory(sheetsDir).createSync();
      }
      if (!Directory(cacheDir).existsSync()) {
        Directory(cacheDir).createSync(recursive: true);
      }
      cleanupFiles();
      //});
    }

    SharedPreferences.getInstance().then((value) {
      prefs = value;
      getSettings();
      initData();

      if (Platform.isAndroid) {
        unsavedChanges = prefs.getStringList(fileContentsKey) ?? [];
        if (unsavedChanges.isNotEmpty) {
          for (var element in unsavedChanges) {
            try {
              var arr = element.split(';');
              String table = arr[0];
              int row = int.parse(arr[1]);
              int cell = int.parse(arr[2]);
              String value = arr[3];
              excel!.tables[table]!.rows[row][cell]!.value =
                  TextCellValue(value);
            } catch (err) {
              print(err);
            }
          }
          saveExcel();
        }
      }
      FastCachedImageConfig.init(
              subDir: cacheDir, clearCacheAfter: const Duration(days: 365 * 99))
          .then((value) => setState(() {}));
    });
  }

  void requestPermissions() async {
    var statusA = await Permission.storage.status;
    var statusB = await Permission.manageExternalStorage.status;
    if (!statusA.isGranted || !statusB.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.manageExternalStorage,
        Permission.storage,
      ].request();
    }
  }

  List<Widget> buildSheetPicker() {
    List<Widget> temp = [];
    for (int i = 0; i < sheets.length; i++) {
      String name = sheets[i];
      temp.add(buildContainer(Text(name),
          color: i == sheetIndex ? Colors.white24 : Colors.white10, mh: 4));
    }
    return temp;
  }

  Widget buildSheetsView() {
    var controller = TabController(
        initialIndex: sheetIndex, length: sheets.length, vsync: this);
    controller.addListener(() {
      sheetIndex = controller.index;
      var b = excel!.setDefaultSheet(sheets[sheetIndex]);
      if (b) {
        //File(file).writeAsBytesSync(excel!.encode()!);
      }
      //initData();
      initTable();
      setState(() {});
    });
    return sheets.length < 2
        ? Container()
        : tabsLayout
            ? TabBar(
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                isScrollable: true,
                controller: controller,
                tabs: buildSheetPicker())
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Current Sheet:'),
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: DropdownButton<String>(
                      value: sheets[sheetIndex],
                      elevation: 16,
                      onChanged: (String? value) {
                        sheetIndex = sheets.indexOf(value!);
                        var b = excel!.setDefaultSheet(sheets[sheetIndex]);
                        if (b) {
                          //File(file).writeAsBytesSync(excel!.encode()!);
                        }
                        //initData();
                        initTable();
                        setState(() {});
                      },
                      items:
                          sheets.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(value)),
                        );
                      }).toList(),
                    ))
              ]);
  }

  @override
  Widget build(BuildContext context) {
    mainState = setState;
    mcontext = context;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    List<List<Data?>> rows = excel?.tables[table]?.rows ?? [];
    maxColumns = getMaxColumns();

    if (cellWidthBaseline == -1) {
      var d = screenWidth / 147;
      maxColumns = d.toInt();
      var row = rows[0];
      List<int> flexWidths = [];

      for (int i = 0; i < row.length; i++) {
        var cell = row[i];
        if (cell == null || cell.value == null) continue;
        final value = cell.value;

        if (i >= maxColumns) {
          if (i == maxColumns) {
            flexWidths.add(7);
          }
          break;
        }
        flexWidths.add(
            mDataCell(row: cell.rowIndex, cell: cell.columnIndex, data: value)
                .getFlex());
      }
      var diff =
          flexWidths.reduce((value, element) => value + element) * 14 / 147;
      var div = 147 - diff;
      cellWidthBaseline = div.floor().toInt();
      prefs.setInt(cellWidthKey(file, sheets[sheetIndex]), cellWidthBaseline);
      maxColumns = getMaxColumns();
    }

    if (!ignoreSort && lazyBuild) {
      var header = rows.removeAt(0);
      rows.sort((a, b) {
        var aVal = '${a[sortColumnIndex]?.value}';
        var bVal = '${b[sortColumnIndex]?.value}';

        if (isNumber(aVal) && isNumber(bVal)) {
          try {
            return int.parse(aVal).compareTo(int.parse(bVal));
          } catch (e) {}
        }

        return aVal.trim().toLowerCase().compareTo(bVal.trim().toLowerCase());
      });

      if (sortColumnMode == 1) {
        rows = rows.reversed.toList();
      }
      rows.insert(0, header);
    }

    Widget header;
    if (tableBuilder) {
      header = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller1,
          child: buildHeader());
    } else {
      header = buildHeader();
    }

    Widget listView;
    if (tableBuilder) {
      listView = lazyBuild
          ? Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _controller2,
                      child: Column(
                          children: List.generate(rowCount, (row) {
                        return buildRow(context, row, rows);
                      })))))
          : Expanded(
              child: SingleChildScrollView(
                  child: SingleChildScrollView(
                      controller: _controller2,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [...getData(context)],
                      ))));
    } else {
      listView = lazyBuild
          ? Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                      children: List.generate(rowCount, (row) {
                    return buildRow(context, row, rows);
                  }))))
          : Expanded(
              child: SingleChildScrollView(
                  child: Column(
              children: [...getData(context)],
            )));
    }

    int c = getCount();

    return RawKeyboardListener(
        autofocus: true,
        focusNode: mainFocus,
        onKey: _onKey,
        child: SafeArea(
            child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  buildCount(c),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.isEmpty ? 'Choose' : getFileName(file),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatefulBuilder(builder: (BuildContext context, state) {
                    saveBtnState = state;
                    return isSaving
                        ? const CircularProgressIndicator()
                        : IconButton(
                            tooltip: 'Save data; Changes color if unsaved',
                            onPressed: () async {
                              saveExcel();
                              initData();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.save,
                              color: unsaved
                                  ? Colors.deepOrange
                                  : Colors.lightGreen,
                            ));
                  }),
                ],
              ),
              //Wrap(
              //  children: buildSheetPicker(),
              //),
              Row(children: [
                const SizedBox(width: 8),
                //IconButton(
                //    tooltip: 'Go to settings page',
                //    onPressed: () async {
                //      Navigator.push(context, MaterialPageRoute<void>(
                //        builder: (BuildContext context) {
                //          return const SettingsPage();
                //        },
                //      ));
                //    },
                //    icon: const Icon(Icons.settings)),
                Expanded(
                    child: TextField(
                  focusNode: searchFocus,
                  onTapOutside: (e) {
                    mainFocus.requestFocus();
                  },
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white : Colors.black),
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
                      icon: Icon(Icons.clear,
                          color: darkMode ? Colors.white : Colors.black),
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
                )),
                _buildOptionsPopup()
              ]),
              sheets.isEmpty ? Container() : buildSheetsView(),
              header,
              listView
            ],
          ),
          floatingActionButton: showAddBtn
              ? FloatingActionButton(
                  onPressed: () {
                    List<Data?> temp = [];
                    for (int i = 0; i < columnCount; i++) {
                      var data =
                          Data.newData(excel!.sheets[table]!, rowCount + 1, i);
                      data.value = TextCellValue(' ');
                      temp.add(data);
                    }
                    excel!.sheets[table]?.rows.add(temp);
                    //File(file).writeAsBytesSync(excel!.encode()!);
                    setState(() {});
                  },
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.add),
                )
              : null,
        )));
  }

  void searchListClearPressed() {
    searchCtrl.text = '';
    setState(() {});
  }
}

bool isSaving = false;

void saveExcel() {
  try {
    isSaving = true;
    saveBtnState(() {});
    File(file).writeAsBytesSync(excel!.encode()!);
    unsaved = false;
    unsavedChanges = [];
    prefs.setStringList(fileContentsKey, []);
    isSaving = false;
    saveBtnState(() {});
  } catch (e) {
    showErrorDialog('There was an error saving the file.');
  }
}

void showErrorDialog(String msg) {
  showDialog(
      context: mcontext,
      builder: (BuildContext context) => Dialog(
          backgroundColor: darkMode ? Colors.grey.shade700 : Colors.white,
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: StatefulBuilder(builder: (BuildContext context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Error',
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    )),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      msg,
                    )),
              ],
            );
          })));
}
