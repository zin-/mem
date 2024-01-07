class PreferenceKey<T> {
  final String value;
  final Type type;

  PreferenceKey(this.value, this.type);

  @override
  String toString() => value;
}