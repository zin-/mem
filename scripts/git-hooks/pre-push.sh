#!/bin/sh
# scripts/git-hooks/pre-push.sh

# Taskコマンドがパスに通っているか、またはプロジェクトローカルにインストールされていることを想定

# Task を実行して pre-push-checks タスクを呼び出す
echo "Running pre-push checks via Task..."

# ルートディレクトリで task を実行するように変更
cd "$(git rev-parse --show-toplevel)"

task flutter:pre-push-checks

# task の終了コードをフックの終了コードとして使用
exit $?
