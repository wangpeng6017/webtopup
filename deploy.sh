#!/bin/bash
set -euo pipefail

## 本地编译前端，再把 public/build 发布到服务器。
## 生产机内存不够，不要在服务器上执行 npm run build。

S_PATH=/data/www/webtopup # 服务器上的项目目录
ALL_SERVER="webtopup" # 逗号分隔的 SSH Host，仅 -h all 时使用。名称对应 ~/.ssh/config

DIST_DIR=public/build # Vite 产物目录
DIST_FILE=build.zip # 压缩文件名

## 帮助信息
helper() {
    echo "Usage:"
    echo "  ./deploy.sh -h SERVER_HOST [-b]"
    echo "Description:"
    echo "  SERVER_HOST  ~/.ssh/config 里的 Host，多个用逗号分隔；all 使用 ALL_SERVER。"
    echo "  -b           先在本地执行 npm run build，再打包上传。"
    echo "               不加 -b 时复用已有的 ${DIST_FILE}。"
    exit 1
}

## 获取参数
BUILD="false"
HOST="-"

while getopts 'h:b' OPT; do
    case $OPT in
        h) HOST="$OPTARG";;
        b) BUILD="true";;
        ?) helper;;
    esac
done

## 全部
if [ "$HOST" = "all" ]; then
    if [ -z "$ALL_SERVER" ]; then
        printf "*** 请先在脚本里配置 ALL_SERVER ***\n"
        helper
    fi
    HOST=$ALL_SERVER
elif [ "$HOST" = "-" ]; then
    printf "*** 请输入 SERVER_HOST 参数 ***\n"
    helper
fi

# 本地编译。编译失败时不上传旧包。
if [ "$BUILD" = "true" ]; then
    printf ">>> 本地编译前端...\n"
    rm -f "$DIST_FILE"
    npm run build
fi

if [ ! -d "$DIST_DIR" ]; then
    printf "*** 没有 %s，请加上 -b 在本地编译 ***\n" "$DIST_DIR"
    exit 1
fi

## 没有 zip 文件时再压一次，避免重复打包
if [ ! -f "$DIST_FILE" ]; then
    printf ">>> 正在压缩 %s...\n" "$DIST_FILE"
    zip -r -q "$DIST_FILE" "$DIST_DIR" -x "*.DS_Store"
fi

## 服务器部署
IFS=',' read -r -a HOSTARR <<< "$HOST"
for SERVER in "${HOSTARR[@]}"; do
    SERVER=$(echo "$SERVER" | xargs)
    [ -z "$SERVER" ] && continue

    SERVER_SPACE="${SERVER}:${S_PATH}"
    printf ">>> 正在上传 %s 到 %s...\n" "$DIST_FILE" "$SERVER_SPACE"
    scp -q "$DIST_FILE" "${SERVER_SPACE}/${DIST_FILE}"

    printf ">>> 部署服务器 %s\n" "$SERVER"
    ssh "$SERVER" "bash -s" << eeooff
set -euo pipefail
cd "${S_PATH}"
rm -rf public/build public/hot
unzip -o -q ${DIST_FILE}
rm -f ${DIST_FILE}
eeooff
    printf "**** 完成部署 %s ****\n\n" "$SERVER"
done

echo ">>> ALL DONE!"
