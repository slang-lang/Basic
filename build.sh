SLANG="slang"
COMPILER="Compiler.os"
CC="gcc"

function comp {
    BN=$(basename -s .bas $1)
    TTOUTPUT=$(${SLANG} ./${COMPILER} $1 2>&1)
    echo ${TTOUTPUT}

    if [ $? -ne 0 ]; then
        echo "${TTOUTPUT}"
    else
        mv output.c ${BN}.c
        CCOUTPUT=$(${CC} -o ${BN} ${BN}.c)
        if [ $? -ne 0 ]; then
            echo "${CCOUTPUT}"
        else
            echo "${TTOUTPUT}"
        fi
    fi
}

if [ $# -eq 0 ]; then
    for i in $(ls examples/*.bas); do
        comp $i
    done
else
    comp $1
fi

