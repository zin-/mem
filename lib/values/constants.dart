// FIXME rename directory `values` to `constants`
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// FIXME l10nに配置するべき
const somethingWrong = "Something wrong";
// FIXME settingsに配置するべき
const defaultStartOfDay = TimeOfDay(hour: 0, minute: 0);

const methodChannel = MethodChannel('zin.playground.mem');
const requestPermissions = 'requestPermissions';
const permissionNames = 'permissionNames';