#!/usr/bin/env burl

# configure apisix
TEST_PORT=9443

ADMIN put /ssls/1 -d '{
    "cert": "'"$(<${BURL_ROOT}/examples/server.crt)"'",
    "key": "'"$(<${BURL_ROOT}/examples/server.key)"'",
    "snis": [
        "localhost"
    ]
}'

ADMIN put /routes/1 -s -d '{
    "uri": "/httpbin/*",
    "plugins": {
        "limit-count": {
            "count": 2,
            "time_window": 5,
            "rejected_code": 503,
            "key_type": "var",
            "key": "remote_addr"
        }
    },
    "upstream": {
        "scheme": "https",
        "type": "roundrobin",
        "nodes": {
            "nghttp2.org": 1
        }
    }
}'



TEST 1: test if limit-count works

# consume the quota
for ((i=0;i<2;i++)); do
    # send request
    REQ /httpbin/get -X GET --http3-only

    # validate the response headers
    HEADER -ix "HTTP/3 200"
done

# no quota
REQ /httpbin/get -X GET --http3-only
HEADER -x "HTTP/3 503"
HEADER -ix "x-ratelimit-remaining: 0"

# wait for quota recovery
sleep 5

REQ /httpbin/get -X GET --http3-only
HEADER -x "HTTP/3 200"
HEADER -ix "x-ratelimit-remaining: 1"
