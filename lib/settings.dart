import 'dart:io';

import 'package:excel_test/prefs.dart';
import 'package:excel_test/theme.dart';
import 'package:excel_test/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController assetDirCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    assetDirCtrl.text = assetDir;
  }

  @override
  void dispose() {
    prefs.setBool(tabsKey, tabsLayout);
    prefs.setBool(lazyBuildKey(file, sheets[sheetIndex]), lazyBuild);
    prefs.setInt(cellWidthKey(file, sheets[sheetIndex]), cellWidthBaseline);
    prefs.setInt(maxLinesKey(file, sheets[sheetIndex]), maxLines); //
    prefs.setDouble(imgSizeKey(file, sheets[sheetIndex]), imgSize);
    prefs.setBool(ignoreSortKey(file, sheets[sheetIndex]), ignoreSort);
    prefs.setString(checkedFilterKey(file, sheets[sheetIndex]), checkedValue);
    prefs.setString(favoriteFilterKey(file, sheets[sheetIndex]), favoriteValue);
    prefs.setBool(timeframeFilterKey(file, sheets[sheetIndex]), useCurrentTime);
    prefs.setString(assetDirKey(file), assetDir);
    prefs.setBool(showAddBtnKey(file), showAddBtn);
    prefs.setBool(tableBuilderKey(file, sheets[sheetIndex]), tableBuilder);
    try {
      mainState(() {});
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var rows = excel?.tables[table]?.rows ?? [];
    rowCount = rows.length;

    var row = rows[0];
    List<String> sortKeys = row.map((e) => e?.value.toString() ?? "").toList()
      ..removeWhere((element) => element.isEmpty);

    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                buildSectionHeader('Sheet Settings'),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                      const Text('Sort by: '),
                      buildInfoButton(context, 'Sort the list by column values',
                          'Can be alphabetic or numeric, depending on the data.\n\nReverse will reverse the results\n\nNote: both these settings can be changed by tapping the column headers, try it out!\nThe only reason this is shown here is in case you want to sort by a column that isn\'t visible'),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                          dropdownColor: darkMode
                              ? const Color.fromARGB(255, 90, 90, 90)
                              : Colors.white,
                          hint: Text(
                            sortKeys[sortColumnIndex],
                            style: TextStyle(
                                color: !darkMode
                                    ? Colors.black87
                                    : Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          items: sortKeys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                    color: (darkMode
                                        ? Colors.white60
                                        : Colors.black87)),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                          onChanged: (s) async {
                            sortColumnIndex = sortKeys.indexWhere(
                                (element) => element.contains(s ?? ""));

                            setState(() {});
                            //filter();
                            //state(() {});
                          }),
                      const SizedBox(width: 16),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Reverse Sort: '),
                        Checkbox(
                            value: sortColumnMode == 1,
                            onChanged: (b) {
                              sortColumnMode = b ?? false ? 1 : 0;
                              setState(() {});
                            }),
                      ]),
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Lazy Build: '),
                      buildInfoButton(
                          context,
                          'Build rows as they become visible',
                          'Can increase performance when checked, probably not important for small lists unless the data is complex.\n\nNote: If lazy build is chosen, there will be no group layouts displayed'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                lazyBuild = value ?? isLargeFile();
                                state(() {});
                              },
                              value: lazyBuild,
                            ));
                          }))
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Tabs layout: '),
                      buildInfoButton(context, 'Show tabs as sheet selector',
                          'If not checked, show a dropdown instead'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                tabsLayout = value ?? Platform.isAndroid;
                                state(() {});
                              },
                              value: tabsLayout,
                            ));
                          }))
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('No Sorting: '),
                      buildInfoButton(context, 'Whether sorting is done or not',
                          'Whether sorting is done or not. Can be useful if you want to shuffle or use drop down functionality.'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                ignoreSort = value ?? false;
                                state(() {});
                              },
                              value: ignoreSort,
                            ));
                          }))
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Filter by Timeframe:'),
                      buildInfoButton(
                          context,
                          'Filters out items that aren\'t in the current selected time',
                          'Selected time is now by default. If there is no timeframe data, this has no effect'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                useCurrentTime = value ?? useCurrentTime;
                                state(() {});
                              },
                              value: useCurrentTime,
                            ));
                          })),
                      TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: currentTime,
                                firstDate: DateTime(1970, 1),
                                lastDate: DateTime(1971, 1)
                                    .subtract(const Duration(microseconds: 1)));
                            if (picked != null && picked != currentTime) {
                              setState(() {
                                currentTime = picked;
                              });
                            }
                          },
                          child: buildContainer(Text(
                              DateFormat('MMMM / dd').format(currentTime)))),
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Checked Filter:'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: DropdownButton<String>(
                            value: checkedValue,
                            elevation: 16,
                            onChanged: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                checkedValue = value!;
                              });
                            },
                            items: checkedChoices
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(value)),
                              );
                            }).toList(),
                          )),
                      buildInfoButton(context, 'Used to filter checked items',
                          'If there is a filter chosen, only the items matching the specified criteria are shown\n\n If there are no checked columns / data or "Any" is selected, this affects nothing'),
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Favorite Filter:'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: DropdownButton<String>(
                            value: favoriteValue,
                            elevation: 16,
                            onChanged: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                favoriteValue = value!;
                              });
                            },
                            items: favoriteChoices
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(value)),
                              );
                            }).toList(),
                          )),
                      buildInfoButton(context, 'Used to filter favorite items',
                          'If there is a filter chosen, only the items matching the specified criteria are shown\n\n If there are no favorite columns / data or "Any" is selected, this affects nothing'),
                    ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Cell Width Multiplier:'),
                  buildInfoButton(
                      context,
                      'How many columns will be drawn on screen',
                      'Lower value (size) means more columns will be rendered in proportion to this window\'s size'),
                  Expanded(
                      child: Slider(
                    value: cellWidthBaseline.toDouble(),
                    max: 300,
                    min: 25,
                    label: cellWidthBaseline.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        cellWidthBaseline = value.toInt();
                      });
                    },
                  ))
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Max Lines:'),
                  buildInfoButton(
                      context,
                      'How many lines of text can be rendered in a cell',
                      'How many lines of text can be rendered in a cell. If 15 is selected, there will be no limit.'),
                  Expanded(
                      child: Slider(
                    value: maxLines.toDouble(),
                    max: 15,
                    min: 1,
                    label: maxLines.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        maxLines = value.toInt();
                      });
                    },
                  ))
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Image Size:'),
                  buildInfoButton(context, 'How big the images are',
                      'If there are images, then they will use this setting to determine their size'),
                  Expanded(
                      child: Slider(
                    value: imgSize.toDouble(),
                    max: 300,
                    min: 10,
                    label: imgSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        imgSize = value;
                      });
                    },
                  ))
                ]),
                buildSectionHeader('File Settings'),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Show add button: '),
                      buildInfoButton(
                          context, 'Show add button', 'Show add button'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                showAddBtn = value ?? false;
                                state(() {});
                              },
                              value: showAddBtn,
                            ));
                          }))
                    ]),
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Table View: '),
                      buildInfoButton(context, 'Table View', 'Table View'),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StatefulBuilder(
                              builder: (BuildContext context, state) {
                            return buildContainer(Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              side: MaterialStateBorderSide.resolveWith(
                                (states) => const BorderSide(
                                    width: 2.0, color: Colors.white70),
                              ),
                              onChanged: (value) {
                                tableBuilder = value ?? false;
                                state(() {});
                              },
                              value: tableBuilder,
                            ));
                          }))
                    ]),
                Row(children: [
                  const Text('Assets Directory:'),
                  buildInfoButton(
                      context,
                      'Use a different directory for assets',
                      'The assets directory is created for you by default, but you can choose to specify a new location for assets\n\nThis can be useful if you have multiple assets of the same name, but you want to separate them by file. (eg: turnip pic in game a and game b, the app pics one at random unless you specify which game\'s directory to use)'),
                  Expanded(
                      child: TextField(
                    controller: assetDirCtrl,
                    onChanged: (value) {
                      assetDir = value;
                    },
                  )),
                  TextButton(
                      onPressed: () {
                        assetDir = defaultAssetDir;
                        assetDirCtrl.text = assetDir;
                      },
                      child: const Text('Default'))
                ]),
                buildSectionHeader('Utils'),
                //TextButton(
                //    onPressed: () {
                //      exportAllFiles();
                //    },
                //    child: const Text('Export All')),
                Row(children: [
                  Expanded(child: Text('Your sheets directory: $sheetsDir')),
                  IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: sheetsDir));
                      },
                      icon: const Icon(Icons.copy))
                ]),
                Row(children: [
                  TextButton(
                      onPressed: () {
                        showAuditDialog(context);
                      },
                      child: const Text('Audit')),
                  buildInfoButton(context, 'View recent changes',
                      'View a list of recent changes made to the current sheet or all sheets in the file')
                ])
              ])),
        ));
  }
}

Widget buildSectionHeader(String label) {
  return Column(children: [
    const SizedBox(height: 16),
    Row(
      children: [
        const SizedBox(
            width: 32,
            child: Divider(endIndent: 8, color: Colors.white54, height: 4)),
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Expanded(
            child: Divider(indent: 8, color: Colors.white54, height: 4))
      ],
    ),
    const SizedBox(height: 16),
  ]);
}

Widget buildInfoButton(BuildContext context, String label, String info) {
  return IconButton(
      tooltip: label,
      onPressed: () {
        showInfoDialog(context, label, info);
      },
      icon: const Icon(Icons.info_outline));
}

Future<void> showInfoDialog(
    BuildContext context, String title, String msg) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        content: Text(msg),
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
