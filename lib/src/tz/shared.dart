abstract class BaseTimezone {
  final String name;
  final Duration stdOffset;
  ({int dstOn, int dstOff})? transition(int year);
  BaseTimezone(
    this.name, {
    required this.stdOffset,
  });
}
