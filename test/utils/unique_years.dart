/// We want to test every possible type of year
/// (leap year, non-leap year, starting-day-of-week)
/// The following function [uniqueYears] and helper class [_UniqueYears]
/// will generate all the 14 unique years that satisfy the above conditions
library;

Set<int> uniqueYears([int? startYear]) {
  final uniqueYears = <_UniqueYears>{};
  var year = startYear ?? DateTime.now().year;
  while (uniqueYears.length != 14) {
    uniqueYears.add(_UniqueYears(
        weekday: DateTime(year, 1, 1).weekday,
        isLeapYear: _isLeapYear(year),
        year: year));
    year++;
  }
  return uniqueYears.map((e) => e.year).toSet();
}

bool _isLeapYear(int year) =>
    (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

class _UniqueYears {
  final int weekday;
  final bool isLeapYear;
  final int year;
  _UniqueYears({
    required this.weekday,
    required this.isLeapYear,
    required this.year,
  });

  @override
  bool operator ==(covariant _UniqueYears other) {
    if (identical(this, other)) return true;

    return other.weekday == weekday && other.isLeapYear == isLeapYear;
  }

  @override
  int get hashCode => weekday.hashCode ^ isLeapYear.hashCode;
}
