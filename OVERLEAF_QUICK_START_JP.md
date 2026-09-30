# Overleafクイックスタート

## Overleafとは

Overleafは、ブラウザー上でLaTeX文書を編集し、PDFへコンパイルできるオンラインサービスです。大学PCへLaTeXをインストールする必要はありません。RまたはStataで生成した`.tex`表と`.pdf`図をアップロードし、`report.tex`から読み込めます。

## アカウント作成

1. https://www.overleaf.com/register を開く。
2. Google、ORCID、メールアドレスとパスワード、または大学のSSOから登録方法を選ぶ。
3. ログイン後、`New Project`から`Blank Project`を作る。または、配布されたOverleaf用フォルダをZIPにし、`Upload Project`で読み込む。
4. `report.tex`を開き、`Recompile`を押してPDFが表示されることを確認する。

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

1. Rの`analysis.R`またはStataの`analysis.do`を最初から実行する。
2. 生成された`.tex`表と`.pdf`図をOverleafへアップロードする。
3. `report.tex`で`\input{}`と`\includegraphics{}`を使って読み込む。
4. `Recompile`してPDFを確認する。
5. 分析を変更した場合は、生成ファイルの再アップロードを忘れない。
