#!/bin/zsh

TARGET="stream"
INPUT="./imfiles/set_image.mem"
OUTPUT="./sim_risc16ba.dump"
REF_DUMP="./imfiles/median.dump"
CHECK_LOG="./check.log"
C_LOG="./c.log"

gcc ${TARGET}.c -o ${TARGET} && ./${TARGET} ${INPUT} ${OUTPUT} && diff ${OUTPUT} ${REF_DUMP} >! ${CHECK_LOG}

./${TARGET} ${INPUT} ${OUTPUT} >! ${C_LOG}
