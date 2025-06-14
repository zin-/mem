# Local environment

ローカル環境、ローカル開発環境

Devlopper（開発者）が開発を行う環境  
(Public)Development environment（公開開発環境）と区別するために"ローカル"をつけている

## Task Runner

タスクランナー、ビルドツール、コマンドランナー

ローカルでの依存関係解決から、lint、CI上でのビルドまでを行うツール

```bash
brew install go-task/tap/go-task
```

詳細な実行内容は[Taskfile.yml](../Taskfile.yml)を参照すること

# Memo

## Task Runner

いくつかあるので、それぞれの所感と選択理由

- [Makefile](https://makefiletutorial.com/)
  - 記述が古くて、個人的に読みづらい
  - 色んな現場、プロジェクトで利用されているのを見るので、新しいものがあれば他のツールを使いたい
- [Just](https://just.systems/)
  - Rust製
  - 以下ChatGPTの説明
    - 簡潔で気軽に書きやすい
    - 依存関係の記述が複雑？できない？
    - CI/CDでの利用が主眼ではなさそう
    - yamlとは異なる記述
- [Task](https://taskfile.dev/)
  - Go製
  - yamlで記述
  - 全体を管理するならこちら

ということで、Taskを使ってみる
