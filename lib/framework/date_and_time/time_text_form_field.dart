import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/seconds_of_time_picker.dart';
import 'package:mem/features/logger/log_service.dart';

// TODO: 以下の改善を検討
// - 数値キーボードの表示（keyboardType: TextInputType.number）
// - 基本的な数値バリデーションの追加
// - ヒントテキストの改善（より具体的な例の提示）
// - エラーメッセージのローカライズ対応
// - 最小値・最大値のバリデーション追加
// - エラーメッセージのカスタマイズ機能追加
class TimeTextFormField extends StatelessWidget {
  final int? secondsOfTime;
  final void Function(int? pickedSecondsOfTime) _onChanged;

  const TimeTextFormField(
    this.secondsOfTime,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return TextFormField(
            controller: TextEditingController(
              text: formatSecondsOfTime(secondsOfTime),
            ),
            decoration: InputDecoration(
              hintText: 'h:m',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final picked = await showSecondsOfTimePicker(
                    context,
                    secondsOfTime,
                  );

                  if (picked != null) {
                    _onChanged(picked);
                  }
                },
              ),
            ),
          );
        },
        secondsOfTime,
      );
}
