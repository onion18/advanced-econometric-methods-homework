# Overleafクイックスタート

## Overleafとは

Overleafは、ブラウザー上でLaTeX文書を編集し、PDFへコンパイルできるオンラインサービスです。大学PCへLaTeXをインストールする必要はありません。RまたはStataで生成した`.tex`表と`.pdf`図を、`report/report.tex`から読み込みます。

## アカウント作成

1. https://www.overleaf.com/register を開く。
2. Google、ORCID、メールアドレスとパスワード、または大学のSSOから登録方法を選ぶ。
3. ログイン後、`New Project`から`Blank Project`を作る。または、配布されたOverleaf用フォルダをZIPにし、`Upload Project`で読み込む。
4. `report/report.tex` を開き、`Recompile` を押して PDF が表示されることを確認する。Overleaf が自動でそのファイルを選ばないときは、メインファイルに指定する。

## 無料プランの範囲（2026年9月確認）

無料プランには、次の機能が含まれます。

- プロジェクト数は無制限
- 1プロジェクトにつき共同作業者1名
- 基本のコンパイル時間
- 直近24時間の文書履歴
- 既成テンプレート

個人で行う通常の週次宿題には、原則として無料プランで十分です。複雑な文書で基本コンパイル時間を超える場合、長期の履歴や変更履歴が必要な場合、外部サービスとの連携を使う場合には、有料プランが必要になることがあります。

無料範囲は変更される可能性があります。最新条件は公式ページで確認してください。

- Plans & Pricing: https://www.overleaf.com/user/subscription/plans
- Learn LaTeX in 30 minutes: https://www.overleaf.com/learn/latex/Learn_LaTeX_in_30_minutes

## RまたはStataとの使い方

1. プロジェクトフォルダで `code/analysis.R` または `code/analysis.do` を最初から実行する。
2. スクリプトは `.tex` 表と `.pdf` 図を `output/` に書く。`report/report.tex` はすでにその場所を参照している。
3. `Recompile` して PDF を確認する。
4. 分析を変更した場合は、スクリプトを再実行し、`output/` の新しいファイルをアップロードする。
