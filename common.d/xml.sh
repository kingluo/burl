SET XMLTOJSON <<'EOF'
import json
import sys
import xmltodict
with open(sys.argv[1]) as fd:
    body=xmltodict.parse(fd.read())
    print(json.dumps(body))
EOF

XML() {
    python3 -c "${XMLTOJSON}" "${CURL_RSP_BODY}" | jq "$@"
}
