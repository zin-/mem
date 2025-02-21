import 'package:mem/logger/log_service.dart';
import 'package:workmanager/workmanager.dart';

enum Task {
  notify,
}

class WorkmanagerWrapper {
  static WorkmanagerWrapper? _instance;

  factory WorkmanagerWrapper({
    Function? callbackDispatcher,
    bool isInDebugMode = false,
  }) =>
      _instance ??= WorkmanagerWrapper._(
        callbackDispatcher,
        isInDebugMode,
      );

  final Function? _callbackDispatcher;
  final bool _isInDebugMode;

  late final Workmanager _workmanager = v(
    () {
      final workmanager = Workmanager();
      if (_callbackDispatcher != null) {
        workmanager.initialize(
          _callbackDispatcher,
          isInDebugMode: _isInDebugMode,
        );
      }
      return workmanager;
    },
  );

  WorkmanagerWrapper._(
    Function? callbackDispatcher,
    bool isInDebugMode,
  )   : _callbackDispatcher = callbackDispatcher,
        _isInDebugMode = isInDebugMode;

  Future<void> registerOneOffTask(
    Task task,
    DateTime at,
    int id,
    Map<String, Object?>? inputData,
  ) =>
      v(
        () async => await _workmanager.registerOneOffTask(
          id.toString(),
          task.name,
          initialDelay: at.difference(DateTime.now()),
          inputData: inputData,
        ),
        {
          'task': task,
          'at': at,
          'id': id,
          'inputData': inputData,
        },
      );

  Future<void> registerPeriodicTask(
    Task task,
    DateTime at,
    int id,
    Map<String, Object?>? inputData,
    Duration frequency,
  ) =>
      v(
        () async => await _workmanager.registerPeriodicTask(
          id.toString(),
          task.name,
          initialDelay: at.difference(DateTime.now()),
          inputData: inputData,
          frequency: frequency,
        ),
        {
          'task': task,
          'at': at,
          'id': id,
          'inputData': inputData,
          'frequency': frequency,
        },
      );

  Future<void> cancel(int id) => v(
        () async {
          await _workmanager.cancelByUniqueName(id.toString());
        },
        {
          'id': id,
        },
      );

  void executeTask(
    Future<bool> Function(Map<String, Object?>? inputData) notifyCallback,
  ) =>
      _workmanager.executeTask(
        (task, inputData) => i(
          () async {
            return await notifyCallback(inputData);
          },
          {
            'task': task,
            'inputData': inputData,
          },
        ),
      );

  static void resetSingleton() => v(
        () {
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );
}
