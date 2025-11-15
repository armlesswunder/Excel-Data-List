import 'dart:io';

import 'package:excel_test/data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../prefs.dart';
import '../theme.dart';
import '../utils.dart';
import 'display_item.dart';

StateSetter? listState;
double cacheListsPosition = 0.0;
late TextEditingController searchListDisplayController;

get listScrollCacheKey => 'FILE_SELECTION_CACHED_SCROLL_POSITION';

class ABWFilePickerPage extends StatefulWidget {
  const ABWFilePickerPage({Key? key}) : super(key: key);

  @override
  State<ABWFilePickerPage> createState() => _ABWFilePickerPageState();
}

class _ABWFilePickerPageState extends State<ABWFilePickerPage> {
  bool hideStuff = true;

  ScrollController _listController = ScrollController();
  late FocusNode _optionsFocusNode;
  MenuController? _menuController;

  Directory directory() => Directory(currentDir);
  String currentDir = '';

  List<DisplayItem> get dataList =>
      directory().listSync().map((e) => DisplayItem(e.path)).toList();

  void mSetState() {
    if (listState != null) {
      listState!(() {});
      if (_listController.hasClients) {
        cacheListsPosition = _listController.position.pixels;
        prefs.setDouble(listScrollCacheKey, cacheListsPosition);
        _listController = ScrollController(
            initialScrollOffset: _listController.position.pixels);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    searchListDisplayController = TextEditingController();
    if (cacheListsPosition > 0) {
      _listController =
          ScrollController(initialScrollOffset: cacheListsPosition);
    }
    _optionsFocusNode = FocusNode();
    currentDir = File(file).parent.path;
    var l = Directory(currentDir).listSync(); //
    print(l.length); //
  }

  @override
  void dispose() {
    listState = null;
    _optionsFocusNode.dispose();
    searchListDisplayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildListScreen();
  }

  Widget buildListScreen() {
    listState = setState;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: showDirUpBtn() ? 16 : 0),
              showDirUpBtn()
                  ? Container(
                      decoration: const BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => moveToParentDirectory(context),
                        icon: Icon(Icons.upload_rounded,
                            color: darkMode ? Colors.white : Colors.black),
                      ))
                  : Container(),
              Expanded(child: buildListSearchBar()),
              _buildOptionsPopup()
            ],
          ),
          Expanded(
              key: UniqueKey(),
              child: Scrollbar(
                thumbVisibility: isMobile() ? false : true,
                thickness: isMobile() ? 0.0 : 16.0,
                controller: _listController,
                child: ListView.builder(
                    controller: _listController,
                    itemCount: dataList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildListItem(context, index, setState);
                    }),
              ))
        ],
      ),
    );
  }

  Widget _buildOptionsPopup() {
    return MenuAnchor(
      childFocusNode: _optionsFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: showDirCheckboxChanged,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text("Show Directories?  "),
                  _buildShowDirectoryCheckbox(),
                ],
              )),
        ),
        if (!isMobile())
          MenuItemButton(
              onPressed: () {
                chooseDefaultDir(context);
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text('Choose Default List'))),
        if (isMobile())
          MenuItemButton(
              onPressed: () {
                openFile(context);
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4), child: Text('Import List'))),
        //if (isMobile())
        //  MenuItemButton(
        //      onPressed: () {
        //        exportFile();
        //        setState(() {});
        //      },
        //      child: const Padding(
        //          padding: EdgeInsets.all(4), child: Text('Export List'))),
        if (isMobile())
          MenuItemButton(
              onPressed: () {
                exportAllFiles();
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4), child: Text('Export All'))),
      ],
      builder: (_, MenuController controller, Widget? child) {
        _menuController = controller;
        return IconButton(
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

  bool showDirUpBtn() {
    if (isMobile()) {
      return showDirectories && !isTopLevelDir();
    } else {
      return showDirectories;
    }
  }

  //TODO Test me
  bool isTopLevelDir() {
    return directory().path == sheetsDir;
  }

  Widget _buildListItem(BuildContext context, int index, StateSetter state) {
    DisplayItem listItem = dataList[index];
    return showCard(listItem)
        ? GestureDetector(
            onTap: () async {
              if (!listItem.isDirectory()) {
                file = listItem.trueData;
                setDefaultFile(file);
                assetDir =
                    prefs.getString(assetDirKey(file)) ?? defaultAssetDir;
                initData();
                mainState(() {});
              } else {
                currentDir = listItem.trueData;
                _listController.jumpTo(0);
              }
              mSetState();
            },
            child: Container(
                decoration: BoxDecoration(
                    color:
                        getSelectedCardColor(index == getSelectedListIndex()),
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(listItem.getDisplayData()),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: getIcon(listItem)),
                      ),
                    ),
                  ],
                )),
          )
        : Container();
  }

  Widget buildListSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: TextField(
        style: TextStyle(color: darkMode ? Colors.white : Colors.black),
        controller: searchListDisplayController,
        onChanged: onSearchListChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(14),
          isDense: true,
          filled: true,
          fillColor: darkMode ? Colors.white24 : Colors.black26,
          hintText: 'Search',
          hintStyle: TextStyle(color: darkMode ? Colors.white : Colors.black),
          prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.search,
                color: darkMode ? Colors.white : Colors.black,
              )),
          suffixIcon: IconButton(
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
      ),
    );
  }

  void searchListClearPressed() {
    searchListDisplayController.text = "";
    setState(() {});
  }

  void onSearchListChanged(String text) {
    setState(() {});
  }

  bool isMobile() {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  void chooseDefaultDir(BuildContext context) async {
    //if (isAndroid()) return;
    var documentsDir = Directory(sheetsDir);
    String? selectedDirectory = await FilePicker.platform
        .getDirectoryPath(initialDirectory: documentsDir.path);

    if (selectedDirectory != null) {
      await prefs.setString('defaultDir', selectedDirectory);
      //loadDirectory();
    }
  }

  Widget getIcon(DisplayItem listItem) {
    if (listItem.isDirectory()) {
      return Icon(Icons.folder_open_rounded,
          color: darkMode ? Colors.white70 : Colors.black87);
    }
    return Icon(Icons.density_medium_rounded,
        color: darkMode ? Colors.white70 : Colors.black87);
  }

  bool showCard(DisplayItem listItem) {
    if (listItem.isDirectory() && !showDirectories) {
      return false;
    }
    if (!listItem
        .getDisplayData()
        .toLowerCase()
        .contains(searchListDisplayController.text.toLowerCase().trim())) {
      return false;
    }
    return true;
  }

  int getSelectedListIndex() {
    return dataList.indexWhere((element) => element.trueData == file);
  }

  Color dialogColor = const Color.fromARGB(255, 63, 63, 63);

  Widget _buildShowDirectoryCheckbox() {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: showDirectories,
          onChanged: (condition) => showDirCheckboxChanged());
    });
  }

  void showDirCheckboxChanged() {
    showDirectories = !showDirectories;
    prefs.setBool('SHOW_DIRS', showDirectories);
    setState(() {});
    _menuController?.close();
    setState(() {});
  }

  bool createDirs = false;

  void moveToParentDirectory(BuildContext context) async {
    cacheListsPosition = 0;
    try {
      if (directory().existsSync() && directory().parent.existsSync()) {
        currentDir = directory().parent.path;
        setState(() {});
      }
    } catch (e) {
      print(e);
    }
  }
}
