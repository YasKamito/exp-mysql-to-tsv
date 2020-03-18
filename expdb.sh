#!/bin/bash
#set -x

CMDNAME=$(basename $0)
CMDNAMENOEXT=$(basename $0 .sh)
TMP_FILE=$(mktemp /tmp/sqltmp.XXXXXX)
RC_OK=0
RC_ERROR=1
RC_CANCEL=2
FLG_DISABLED=0
FLG_ENABLED=1
VERSION="0.0.1"

trap "rm ${TMP_FILE}" 0 1 2 3 15

## Getting Environment Value
source ./.env

SQLFILE=${SQLFILE}
ENV_DB_HOST=${DB_HOST}
ENV_DB_USER=${DB_USER}
ENV_DB_PASSWORD=${DB_PASSWORD}
ENV_DB_SCHEME=${DB_SCHEME}

CLIPBOARD=${FLG_ENABLED}
TEST_DIR=""
TEST_FILE_PREFIX=""
SQLDIR=""

###############################
# usage
###############################
usage() 
{
cat << EOF
export MySQL Table data to TSV 
$(version)

Usage:
    ${CMDNAME} [--dir </Path/to/dir>] [--file <file-prefix>] [--sqlfile <sql-file-name>]
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

EOF
}

###############################
# version
###############################
version() {
    echo "${CMDNAMENOEXT} version ${VERSION} "
}

###############################
# get options
###############################
get_options()
{

    # get options
    while [ $# -gt 0 ];
    do
        case ${1} in

            --dir|-d)
                TEST_DIR=${2}
                shift
            ;;
            
            --file|-f)
                TEST_FILE_PREFIX=${2}
                shift
            ;;

            --sqlfile|-s)
                SQLFILE=${2}
                shift
            ;;

            --sqldir|-S)
                SQLDIR=${2}
                shift
            ;;

            --clip|-c)
                CLIPBOARD=${FLG_ENABLED}
            ;;

            --version|-v)
                version
                return ${RC_CANCEL}
            ;;
            
            --help|-h)
                usage
                return ${RC_CANCEL}
            ;;

            *)
                usage
                return ${RC_CANCEL}
            ;;

        esac
        shift
    done

}

###############################
# yesno check 
###############################
yesno_chk()
{
  read -p "よろしいですか？(y/n)-->[y]" ANSWER
  while true;do
    case ${ANSWER} in
      yes | y)
        return ${RC_OK}
        ;;
      no | n)
        return ${RC_CANCEL}
        ;;
      *)
        return ${RC_OK}
        ;;
    esac
  done
}

############################
# バックアップファイル作成
############################
create_sv_file()
{
	OLD_FNAME=$1
	SV_FNAME=${OLD_FNAME}.sv
	if [ -e ${SV_FNAME} ]; then
		CNT=0
		SV_FNAME_CP=${SV_FNAME}.${CNT}
		while [ -e ${SV_FNAME_CP} ]
		do
			CNT=$((${CNT} + 1 ))
			SV_FNAME_CP=${SV_FNAME}.${CNT}
		done
		SV_FNAME=${SV_FNAME_CP}
	fi
	echo "既存のファイルをバックアップします： ${OLD_FNAME} -> ${SV_FNAME}"
	mv ${OLD_FNAME} ${SV_FNAME}
}

############################
# ファイル存在チェック
############################
check_test_file()
{
	if [ -e $1 ]; then
        echo "ファイルが既に存在します!!!"
        create_sv_file $1
	fi
	return ${RC_OK}
}

############################
# DBエクスポート関数
############################
db_export()
{
    SQLFILE_NAME=$1
    OUTPUT_FILE_NAME=$2
    echo "Input query file : ${SQLFILE_NAME}"
    echo "Export file      : ${OUTPUT_FILE_NAME}"
    mysql --host ${ENV_DB_HOST} -u${ENV_DB_USER} -p${ENV_DB_PASSWORD} --database "${ENV_DB_SCHEME}" --ssl-cipher=AES256-SHA < ${SQLFILE_NAME} > ${TMP_FILE}
    RC=${?}
    cat ${TMP_FILE} >> ${OUTPUT_FILE_NAME}
    if [ ${RC} -ne ${RC_OK} ]; then
        echo "Error occurred : ${PROCNAME} ${SQLFILE_NAME}"
        exit ${RC_ERROR}
    fi
}

get_db_evidence()
{
    SQL_FILE=$1
    OUTPUT_FILE=$2
    echo "############################"
    echo "DBからデータを取得します"
    echo " Export file : ${OUTPUT_FILE}"
    echo "############################"
    yesno_chk 
    RC=$?
    if [ ${RC} -ne ${RC_OK} ]; then
        echo "テストを中断します"
        exit ${RC}
    fi
    check_test_file ${OUTPUT_FILE}
    db_export ${SQL_FILE} ${OUTPUT_FILE}
}

###############################
#
# main
#
###############################

###############################
# Call get_options
###############################
get_options $@
RC=${?}
[ ${RC} -ne ${RC_OK} ] && exit ${RC}

###############################
# ディレクトリ取得・作成
###############################
if [ -z ${TEST_DIR} ]; then
    echo "出力先ディレクトリを入力してください ex) path/to/dir"
    read -p "> " TEST_DIR
fi
TEST_DIR="log/${TEST_DIR}"
mkdir -p ${TEST_DIR}

###############################
# ファイル名取得
###############################
if [ -z ${TEST_FILE_PREFIX} ]; then
    echo "出力ファイル名を入力してください ex) hogehoge"
    read -p "> " TEST_FILE_PREFIX
fi

###############################
# テスト開始後DBエビデンス取得
###############################
if [ -n "${SQLDIR}" ]; then
    for sql_file in $(find ${SQLDIR} -name "*.sql" -not -name "_*" | sort)
    do
        OUT_WK=$(basename $sql_file | sed 's/.sql//' )
        OUTPUT=${TEST_DIR}/${TEST_FILE_PREFIX}-${OUT_WK}.tsv
        get_db_evidence ${sql_file} ${OUTPUT}
    done
else
    get_db_evidence ${SQLFILE} ${TEST_DIR}/${TEST_FILE_PREFIX}.tsv
    if [ ${CLIPBOARD} -eq ${FLG_ENABLED} ];then
        cat ${TMP_FILE} | pbcopy
    fi
fi
