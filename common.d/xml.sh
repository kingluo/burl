if ! pip3 show xmltodict &>/dev/null; then
    echo "Python module `xmltodict` not exist."
    echo 'Use `pip3 install xmltodict` to install it.'
fi

XMLTODICT='
import sys
import xmltodict
with open(sys.argv[1]) as fd:
    body=xmltodict.parse(fd.read())
exit(eval(sys.argv[2]))
'

XML() {
    set +e
    python3 -c "${XMLTODICT}" "${CURL_RSP_BODY}" "$@"
    local ret=$?
    set -e
    [[ $ret -eq 1 ]]
}

