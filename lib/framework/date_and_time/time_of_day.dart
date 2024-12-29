import 'package:flutter/material.dart';

extension Seconds on TimeOfDay {
  int get seconds => ((hour * 60) + minute) * 60;
}

extension Comparable on TimeOfDay {
  int compareTo(TimeOfDay other) => seconds.compareTo(other.seconds);

  // bool graterThan(TimeOfDay other) => compareTo(other) > 0;

  bool lessThan(TimeOfDay other) => compareTo(other) < 0;
}
