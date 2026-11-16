// Native Postgres returns typed values and HTTP returns numbers as text, so models read through these.
int asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : int.parse(v.toString()));

int? asIntOrNull(Object? v) => v == null ? null : asInt(v);

double asDouble(Object? v) => v is num ? v.toDouble() : double.parse(v.toString());

double? asDoubleOrNull(Object? v) => v == null ? null : asDouble(v);

String asString(Object? v) => v?.toString() ?? '';

String? asStringOrNull(Object? v) => v?.toString();

DateTime? asDateTimeOrNull(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

// "08:00:00" -> "08:00"
String hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

// "13:30" -> "1:30 PM"
String time12(String t) {
  final p = hhmm(t).split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = p.length > 1 ? p[1] : '00';
  final suffix = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $suffix';
}

String dateOnly(DateTime? d) {
  if (d == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
