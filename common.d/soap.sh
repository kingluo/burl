if ! pip3 show zeep &>/dev/null; then
    echo "Python module `zeep` not exist."
    echo 'Use `pip3 install zeep` to install it.'
fi

SET ZEEP <<'EOF'
#!/usr/bin/env python3

import json
import logging
import sys
import traceback
import zeep

logging.basicConfig(
    format="%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
    level=logging.DEBUG,
)


def to_json(obj):
    return json.dumps(
        obj,
        default=lambda o: hasattr(o, "__values__") and o.__values__ or o.__dict__,
    )


def soap_post(url, operation, data):
    try:
        cli = zeep.Client(url)
        try:
            data = json.loads(data)
            body = cli.service[operation](**data)
        except zeep.exceptions.Fault as fault:
            body = fault
        return to_json(body)
    except Exception as exc:
        tb = traceback.format_exc()
        logging.error(tb)
        exit(1)


_, url, operation, data, *_ = sys.argv
print(f"{soap_post(url, operation, data)}")
EOF

#;
# SOAP_REQ()
# Send SOAP request to web service and verify the response
# @param: WSDL URL
# @param: operation name
# @param: operation data in JSON format
# @param: jq expression to verify the response
# @return 0: ok, 1: failed
#"
SOAP_REQ() {
    local url=$1
    local operation=$2
    local data=$3
    local expr=$4
    local stderr=$(mktemp)
    GC "rm -f $stderr"
    set +e
    python3 -c "${ZEEP}" $url $operation $data 2>$stderr | jq "$expr"
    local ret=$?
    set -e
    if [[ $ret != 0 ]]; then
        cat $stderr
        return 1
    fi
}
