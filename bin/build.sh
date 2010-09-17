#!/bin/bash

if [ -n "$1" ]
# 测试是否提供入口类文件名（默认为 Main.as）
then
    MAIN=$1
else
    MAIN=Main.as
fi

PARENT="$(cd "${0%/*}"/.. 2>/dev/null;echo "$PWD")"

CC=mxmlc
CCFLAGS=" $PARENT/src/$MAIN"
# CCFLAGS+=" -debug=true"
CCFLAGS+=" -static-link-runtime-shared-libraries=true"
CCFLAGS+=" -sp+=$HOME/sf/papervision3d/trunk/src/"
CCFLAGS+=" -sp+=$HOME/sf/jiglibflash-read-only/fp10/src"
CCFLAGS+=" -sp+=$HOME/sf/bulk-loader-read-only/src/"
# CCFLAGS+=" -library-path+=$HOME/share/flex4sdk/frameworks/libs/flex.swc"
# CCFLAGS+=" -library-path+=$HOME/sf/alcon/as3/alcon.swc"
CCFLAGS+=" -o $PARENT/bin-debug/${MAIN%.as}.swf"
(
    echo $CC $CCFLAGS

    while : 
    do read n 
        case $n in 
            r)  # 重新编译
                echo compile 1
                ;; 
            q)  # 退出
                exit
                ;; 
        esac 
    done
) | fcsh
