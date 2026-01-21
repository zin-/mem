class Singleton {
  static final Map<Type, dynamic> _instances = {};

  static T of<T>(T Function() creator) =>
      _instances.putIfAbsent(T, creator) as T;

  static void override<T>(T instance) => _instances[T] = instance;

  static void reset<T>() => _instances.remove(T);

  static bool exists<T>() => _instances.containsKey(T);
}
