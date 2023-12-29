ADMIN() {
    method=${1^^};
    resource=$2;
    shift 2;
    curl ${ADMIN_SCHEME:-http}://${ADMIN_IP:-127.0.0.1}:${ADMIN_PORT:-9180}/apisix/admin${resource} \
        -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X $method "$@"
    sleep 1
}
