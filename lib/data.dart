import 'package:excel/excel.dart';
import 'package:excel_test/utils.dart';
import 'package:flutter/cupertino.dart';

import 'data_cell.dart';
import 'model/audit_data.dart';

Excel? excel;
String? table;

List<dynamic> columns = [];
List<List<mDataCell>> rows = [];

int sortColumnIndex = 0;
int sortColumnMode = 0;
int showCbMode = 0;

List<String> unsavedChanges = [];

bool isPaused = false;

late StateSetter mainState;
late StateSetter saveBtnState;
late BuildContext mcontext;

final FocusNode mainFocus = FocusNode();
final FocusNode searchFocus = FocusNode();

String file = '';
String assetDir = '';
String defaultAssetDir = '';
String sheetsDir = '';
String cacheDir = '';

List<String> sheets = [];
List<AuditData> auditData = [];
int sheetIndex = 0;

int columnCount = 0;
int rowCount = 0;
double cellWidthMargin = 2;
double get infoWidth => 32;
int cellWidthBaseline = 147;
double imgSize = 80;
int maxColumns = -1;
int maxLines = 2;
bool lazyBuild = false;
bool tableBuilder = false;
bool headerNotVisible = false;
bool showAddBtn = false;
bool unsaved = false;
bool useCurrentTime = false;
bool showSystemFiles = false;
bool showDirectories = true;
bool ignoreSort = false;
DateTime currentTime = getCurrentDate();

double screenWidth = 0;
double screenHeight = 0;
String checkedValue = checkedChoices.first;
String favoriteValue = favoriteChoices.first;
bool tabsLayout = false;
const List<String> checkedChoices = <String>['Any', 'Checked', 'Unchecked'];
const List<String> favoriteChoices = <String>[
  'Any',
  'Favorite',
  'Not Favorite'
];

int getMaxColumns() {
  if (tableBuilder) return 99;
  var d = screenWidth / cellWidthBaseline;
  return d.toInt();
}
