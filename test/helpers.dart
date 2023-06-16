import 'dart:math';

bool randomBool() => Random().nextBool();

int randomInt([int max = 4294967296]) => Random().nextInt(max);
