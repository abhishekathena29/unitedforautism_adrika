/// Direct port of `src/lib/utils.ts`.
library;

bool isValidEmail(String email) {
  final t = email.trim();
  return t.isNotEmpty && t.contains('@') && t.indexOf('@') > 0;
}

String timeAgo(String iso) {
  final d = DateTime.tryParse(iso)?.millisecondsSinceEpoch ??
      DateTime.now().millisecondsSinceEpoch;
  final s = ((DateTime.now().millisecondsSinceEpoch - d) / 1000).floor();
  final secs = s < 0 ? 0 : s;
  if (secs < 10) return 'Just now';
  if (secs < 60) return '${secs}s';
  if (secs < 3600) return '${(secs / 60).floor()}m';
  if (secs < 86400) return '${(secs / 3600).floor()}h';
  return '${(secs / 86400).floor()}d';
}

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatEventDate(String? date, String? time) {
  if (date == null || date.isEmpty) return '';
  final d = DateTime.tryParse(date);
  if (d == null) return '';
  final day = '${_weekdays[d.weekday % 7]}, ${_months[d.month - 1]} ${d.day}';
  return (time != null && time.isNotEmpty) ? '$day · $time' : day;
}

String initialsFromName(String name) {
  final parts = name.split(' ').where((w) => w.isNotEmpty).toList();
  final letters = parts.map((w) => w[0]).join();
  final slice = letters.length > 2 ? letters.substring(0, 2) : letters;
  return slice.toUpperCase();
}
