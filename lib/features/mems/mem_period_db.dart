import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

// FIXME: [DateAndTimePeriodをDBからDomainに変換する際の処理を共通化する](https://github.com/zin-/mem/issues/629)
// Mems テーブルの列（notifyOn/notifyAt/endOn/endAt）が DateAndTimePeriod
// （start/end）に対応していない負債の橋渡し。
// 本来はスキーマを period に寄せ、この変換自体を消す。
// その前提で、暫定的に features/mems 配下に置くことを許容する。

DateAndTimePeriod? periodFromDb({
  DateTime? notifyOn,
  DateTime? notifyAt,
  DateTime? endOn,
  DateTime? endAt,
}) {
  if (notifyOn == null && endOn == null) {
    return null;
  }
  return DateAndTimePeriod(
    start: notifyOn == null
        ? null
        : DateAndTime.from(
            notifyOn,
            timeOfDay: notifyAt,
          ),
    end: endOn == null
        ? null
        : DateAndTime.from(
            endOn,
            timeOfDay: endAt,
          ),
  );
}

({
  DateTime? notifyOn,
  DateTime? notifyAt,
  DateTime? endOn,
  DateTime? endAt,
}) periodToDb(DateAndTimePeriod? period) => (
      notifyOn: period?.start,
      notifyAt: period?.start?.isAllDay == true ? null : period?.start,
      endOn: period?.end,
      endAt: period?.end?.isAllDay == true ? null : period?.end,
    );
