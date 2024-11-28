int nullableCompare<T extends Comparable>(T? a, T? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;

  return a.compareTo(b);
}
