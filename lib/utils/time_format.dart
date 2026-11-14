/// "12 Nov, 14:05" – small formatter so we don't need the intl package.
String formatDateTime(DateTime? t) {
  if (t == null) return 'just now';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${l.day} ${months[l.month - 1]}, ${two(l.hour)}:${two(l.minute)}';
}
