# Persistence

永続層について検討する

## Database

### [sqflite](https://pub.dev/packages/sqflite)

[公式](https://docs.flutter.dev/cookbook/persistence/sqlite)が推してる  
Android, iOS, MacOSの対応のみ  
Desktop, Webの対応についても[記述している](https://pub.dev/packages/sqflite#more)

ひとまずこれで作ってみて、あとから対応範囲を広げる

[idb_sqflite](https://pub.dev/packages/idb_sqflite)があるようだが・・・？

### [idb_sqflite](https://pub.dev/packages/idb_sqflite)

全プラットフォーム対応っぽい

## [hive](https://pub.dev/packages/hive)

早いらしい
勉強のためにログとか統計解析に使いたいかも

## [Shared preferences plugin](https://pub.dev/packages/shared_preferences)

機能が少ないが高速で手軽というイメージ
ユーザキャッシュや設定値のような揮発してもよいデータを入れると良いかも

ホームウィジェットで利用しているフシがある

## References

- [のんびり精進](https://kabochapo.hateblo.jp/entry/2020/02/01/144411)


