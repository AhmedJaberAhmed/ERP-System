/// Rounds to 2 decimals (matches SQL round(x, 2) for normal values).
double round2(double v) => (v * 100).roundToDouble() / 100;

String fmtMoney(num v) => v.toStringAsFixed(2);

/// 3 -> '3', 2.5 -> '2.5', 1.250 -> '1.25'
String fmtQty(num v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Accepts '12.5' or '12,5'. Returns null when not a number.
double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

/// JSON numeric -> double (PostgREST may send int, double or String).
double asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
