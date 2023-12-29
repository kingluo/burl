SET() {
    set +e
    read -r -d '' $1
    set -e
}

TEST() {
    echo ">>> $@"
}

CURL_TMP=$(mktemp)
CURL_RSP_HEADERS="${CURL_TMP}-headers"
CURL_RSP_BODY="${CURL_TMP}-body"

REQ() {
    curl ${TEST_SCHEME:-https}://${TEST_HOST:-localhost}:${TEST_PORT:-443}"$@" \
        -k -s -S -v -o ${CURL_RSP_BODY} 2>&1 | tee ${CURL_TMP}
    grep -E '^< \w+' ${CURL_TMP} | \
        sed 's/< //g; s/ \r//g; s/\r//g' > ${CURL_RSP_HEADERS}
}

HEADER() {
    grep "$@" ${CURL_RSP_HEADERS}
}

BODY() {
    grep "$@" ${CURL_RSP_BODY}
}

JQ() {
    jq -e "$@" < ${CURL_RSP_BODY}
}

GC_FN_LIST=()

GC() {
    GC_FN_LIST+=("$@")
}

GC_CLEANUP() {
    set +e
    local tmp=()
    for ((i=${#GC_FN_LIST[@]}-1; i>=0; i--)); do
        eval "${GC_FN_LIST[$i]}"
    done
    set -e
}

GC "rm -f ${CURL_TMP}{,-headers,-body}"
trap GC_CLEANUP EXIT INT TERM

for ext in ${BURL_ROOT}/common.d/*.sh; do
    . $ext
done
