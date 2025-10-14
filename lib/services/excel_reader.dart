// lib/services/excel_reader.dart
//import 'dart:ffi';
import 'dart:math';
import 'package:gsheets/gsheets.dart';
import '../core/config.dart';

class ExcelReader {
  static String get _credentials => Config.googleSheetsCredentials;
  static String get _spreedSheetId => Config.googleSheetsSpreadsheetId;
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _converter;

  static Future init() async {
    print('Conectando al a hoja de calculo...');
    final spreadsheet = await _gsheets.spreadsheet(_spreedSheetId);
    _converter =
        await _getWorkSheet(spreadsheet, title: 'Cálculo de Coordenadas');
    print('|| Conectada a la hoja de calculo ||');
  }

  static Future<Worksheet?> _getWorkSheet(Spreadsheet spreadsheet,
      {required String title}) async {
    return await spreadsheet.worksheetByTitle(title);
  }

  static Future<List<double>> modifyLatAndLon(double lat, double long) async {
    var rng = Random();
    int row = rng.nextInt(998) + 2;
    print('Checar la fila----------------$row');

    await _converter!.values.insertValue(lat, column: 2, row: row);
    await _converter!.values.insertValue(long, column: 1, row: row);

    double east =
        double.parse(await _converter!.values.value(column: 30, row: row));
    double north =
        double.parse(await _converter!.values.value(column: 31, row: row));

    return [east, north];
  }
}
