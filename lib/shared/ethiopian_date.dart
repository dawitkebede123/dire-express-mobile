const ethiopianMonthNamesAm = [
  'መስከረም',
  'ጥቅምት',
  'ኅዳር',
  'ታኅሣሥ',
  'ጥር',
  'የካቲት',
  'መጋቢት',
  'ሚያዝያ',
  'ግንቦት',
  'ሰኔ',
  'ሐምሌ',
  'ነሐሴ',
  'ጳጉሜን',
];

const ethiopianWeekdaysAm = ['እሑድ', 'ሰኞ', 'ማክሰ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ'];

class EthiopianDate {
  const EthiopianDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  static EthiopianDate fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    return fromJdn(jdn);
  }

  static EthiopianDate fromJdn(int jdn) {
    const epoch = 1723856;
    final r = (jdn - epoch) % 1461;
    final n = (r % 365) + 365 * (r ~/ 1461);
    final year = 4 * ((jdn - epoch) ~/ 1461) + (r ~/ 365);
    final month = (n ~/ 30) + 1;
    final day = (n % 30) + 1;
    return EthiopianDate(year: year, month: month, day: day);
  }

  DateTime toGregorian() {
    const epoch = 1723856;
    final n = 30 * (month - 1) + (day - 1);
    final jdn = epoch + 365 * year + (year ~/ 4) + n;
    return _jdnToGregorian(jdn);
  }

  int get daysInMonth {
    if (month < 13) return 30;
    return year % 4 == 3 ? 6 : 5;
  }

  EthiopianDate get startOfMonth => EthiopianDate(year: year, month: month, day: 1);

  EthiopianDate addMonths(int delta) {
    var y = year;
    var m = month + delta;
    while (m > 13) {
      m -= 13;
      y++;
    }
    while (m < 1) {
      m += 13;
      y--;
    }
    final dim = EthiopianDate(year: y, month: m, day: 1).daysInMonth;
    return EthiopianDate(year: y, month: m, day: day > dim ? dim : day);
  }

  String get monthName => ethiopianMonthNamesAm[month - 1];

  String format() => '$day $monthName $year';
}

int _gregorianToJdn(int year, int month, int day) {
  final a = ((14 - month) / 12).floor();
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      ((153 * m + 2) / 5).floor() +
      365 * y +
      (y / 4).floor() -
      (y / 100).floor() +
      (y / 400).floor() -
      32045;
}

DateTime _jdnToGregorian(int jdn) {
  var l = jdn + 68569;
  final n = (4 * l) ~/ 146097;
  l = l - (146097 * n + 3) ~/ 4;
  final i = (4000 * (l + 1)) ~/ 1461001;
  l = l - (1461 * i) ~/ 4 + 31;
  final j = (80 * l) ~/ 2447;
  final day = l - (2447 * j) ~/ 80;
  l = j ~/ 11;
  final month = j + 2 - 12 * l;
  final year = 100 * (n - 49) + i + l;
  return DateTime(year, month, day);
}
