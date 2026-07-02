---
description: レビューを依頼された際のルール
globs: *
---

# Review Rules

## レビュー観点
単なる構文エラーやスタイルの指摘にとどまらず、`.cursor/rules/principal-*.md`の「原則」についてコードを評価し、懸念があればフィードバックに含める

# GitHub PR Review Rules

- `gh` コマンドを使用して情報を取得（`gh pr view` や `gh pr diff` など）することは許可する
- **重要:** GitHubへのコメント投稿、レビューの送信、Approveなどの書き込み処理（`gh pr review` や `gh pr comment` など）は実行しない
- 指摘やフィードバックは、すべてCursorのチャット画面内でのテキスト出力に留める