class Singleton {
  static final Map<Type, dynamic> _instances = {};

  static T of<T>(T Function() creator) =>
      _instances.putIfAbsent(T, creator) as T;
}
