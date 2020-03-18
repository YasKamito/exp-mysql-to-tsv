# Export MySQL Table data to TSV

----

# Initialize

* `.env.org` ファイルをコピーして `.env` ファイルを作成し、DBの環境設定を行ってください。

```
$ cp .env.org .env
$ vi .env
---
SQLFILE="./sql/_test.sql"        <----getdb.shでデフォルトで使用するsqlファイル
DB_HOST="example.com"            <----要編集
DB_USER=db_user_name"            <----要編集
DB_PASSWORD="db_password"        <----要編集
DB_SCHEME="database_name"      <----要編集
```

## usage

* 「./expdb.sh」をターミナルに入力し実行
* ログディレクトリを入力
* ログファイル名を入力

```
$ ./expdb.sh 
出力先ディレクトリを入力してください ex) path/to/dir
> path/to/dir
出力ファイル名を入力してください ex) hogehoge
> hogehoge
############################
DBからデータを取得します
 Export file : log/path/to/dir/hogehoge.tsv
############################
よろしいですか？(y/n)-->[y]
Input query file : ./sql/_test.sql
Export file      : log/path/to/dir/hogehoge.tsv
mysql: [Warning] Using a password on the command line interface can be insecure.
```

## options

```
export MySQL Table data to TSV 
expdb version 0.0.1 

Usage:
    expdb.sh [--dir </Path/to/dir>] [--file <file-prefix>] [--sqlfile <sql-file-name>]
                   [--sqldir </Path/to/sqldir>] [--clip]
                   [--vertion] [--help]

Options:
    --dir, -d           出力ファイル格納先ディレクトリ名
    --file, -f          出力ファイル名
    --sqlfile, -s       SQLファイル名
    --sqldir, -S        SQLファイル格納先ディレクトリ名
    --clip, -c          出力結果をクリップボードにコピー（SQLディレクトリ指定時'--sqldir'は無効）
    --version, -v       バージョン情報
    --help, -h          ヘルプ
```
