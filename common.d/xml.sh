SET XMLTODICT <<'EOF'
import sys
import xmltodict
with open(sys.argv[1]) as fd:
    body=xmltodict.parse(fd.read())
exit(eval(sys.argv[2]))
EOF

XML() {
    set +e
    python3 -c "${XMLTODICT}" "${CURL_RSP_BODY}" "$@"
    local ret=$?
    set -e
    [[ $ret -eq 1 ]]
}

