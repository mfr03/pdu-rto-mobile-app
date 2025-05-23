import 'package:intl/intl.dart';

class CFormatter {


  static String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  static DateTime? formatStringToDateTime(String date) {
    if (date == null) {
      return null;
    }

    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }


}