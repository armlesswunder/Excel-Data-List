import 'dart:io';

import 'package:excel_test/model/audit_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

late SharedPreferences prefs;

String fileKey = 'DEFAULT_FILE';
String fileContentsKey = 'DEFAULT_FILE_CONTENTS';
String tabsKey = 'TABS_LAYOUT';

String cellWidthKey(String file, String sheet) =>
    '${file}_${sheet}_CELL_WIDTH_BASELINE';

String imgSizeKey(String file, String sheet) => '${file}_${sheet}_IMG_SIZE';
String ignoreSortKey(String file, String sheet) =>
    '${file}_${sheet}_IGNORE_SORT';
String auditKey(String file, String sheet) => '${file}_${sheet}_AUDIT';
String assetDirKey(String file) => '${file}_ASSET_DIR';
String showAddBtnKey(String file) => '${file}_SHOW_ADD_BTN';
String tableBuilderKey(String file, String sheet) =>
    '${file}_${sheet}_TABLE_BUILDER';

String maxLinesKey(String file, String sheet) => '${file}_${sheet}_MAX_LINES';
String lazyBuildKey(String file, String sheet) => '${file}_${sheet}_LAZY_BUILD';
String checkedFilterKey(String file, String sheet) =>
    '${file}_${sheet}_CHECKED_FILTER';
String favoriteFilterKey(String file, String sheet) =>
    '${file}_${sheet}_FAVORITE_FILTER';
String timeframeFilterKey(String file, String sheet) =>
    '${file}_${sheet}_TIMEFRAME_FILTER';

void getSettings() {
  file = prefs.getString(fileKey) ?? '';
  getSheetSettings();
  tabsLayout = prefs.getBool(tabsKey) ?? Platform.isAndroid;
  assetDir = prefs.getString(assetDirKey(file)) ?? defaultAssetDir;
}

void getSheetSettings() {
  if (file.isNotEmpty && sheets.isNotEmpty) {
    cellWidthBaseline =
        prefs.getInt(cellWidthKey(file, sheets[sheetIndex])) ?? -1;
    maxLines = prefs.getInt(maxLinesKey(file, sheets[sheetIndex])) ?? maxLines;
    imgSize = prefs.getDouble(imgSizeKey(file, sheets[sheetIndex])) ?? 80;
    ignoreSort =
        prefs.getBool(ignoreSortKey(file, sheets[sheetIndex])) ?? false;
    auditData = prefs
            .getStringList(auditKey(file, sheets[sheetIndex]))
            ?.map((e) => AuditData(e))
            .toList() ??
        [];
    checkedValue =
        prefs.getString(checkedFilterKey(file, sheets[sheetIndex])) ??
            checkedValue;
    favoriteValue =
        prefs.getString(favoriteFilterKey(file, sheets[sheetIndex])) ??
            favoriteValue;
    useCurrentTime =
        prefs.getBool(timeframeFilterKey(file, sheets[sheetIndex])) ??
            useCurrentTime;

    lazyBuild = prefs.getBool(lazyBuildKey(file, sheets[sheetIndex])) ??
        excel!.sheets[sheets[sheetIndex]]!.rows.length > 99;

    tableBuilder = prefs.getBool(tableBuilderKey(file, sheets[sheetIndex])) ??
        tableBuilder;
  }
}

void setDefaultFile(String value) {
  prefs.setString(fileKey, value);
}

void setAuditData() {
  if (file.isNotEmpty && sheets.isNotEmpty) {
    var strArr = auditData.map((e) => e.toString()).toList();
    var subList = strArr;
    if (strArr.length > 25) {
      subList = strArr.sublist(0, 25);
    }
    prefs.setStringList(auditKey(file, sheets[sheetIndex]), subList);
  }
}
