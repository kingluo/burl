#!/usr/bin/env burl

# configure apisix
TEST_PORT=9443

ADMIN put /ssls/1 -d '{
    "cert": "'"$(<${BURL_ROOT}/examples/certs/server.crt)"'",
    "key": "'"$(<${BURL_ROOT}/examples/certs/server.key)"'",
    "snis": [
        "localhost"
    ]
}'



TEST 1: test ip-restriction and basic-auth

# configure apisix
ADMIN put /upstreams/1 -s -d '{
    "scheme": "https",
    "nodes":{
        "nghttp2.org":100
    },
    "type":"roundrobin"
}'

ADMIN put /consumers -d '{
    "username":"foobar",
    "plugins":{
        "basic-auth":{
            "password":"bar",
            "username":"foo"
        }
    }
}'

ADMIN put /plugin_configs/1 -d '{
    "plugins":{
        "basic-auth":{},
        "ip-restriction":{
            "whitelist":[
                "172.22.0.1"
            ]
        }
    }
}'

ADMIN put /routes/1 -d '{
    "methods":[
        "GET",
        "POST"
    ],
    "plugin_config_id":"1",
    "upstream_id":"1",
    "uris":[
        "/httpbin/*"
    ]
}'

# Unauthorized
REQ /httpbin/get -X GET --ipv4 --http3-only
HEADER -x "HTTP/3 401"

# Forbidden
REQ /httpbin/get -X GET --ipv4 -u foo:bar --http3-only
HEADER -x "HTTP/3 403"

# make 127.0.0.1 in the whitelist
ADMIN patch /plugin_configs/1/plugins/ip-restriction/whitelist -d '["127.0.0.1"]'

# ok
REQ /httpbin/get -X GET --ipv4 -u foo:bar --http3-only
HEADER -x "HTTP/3 200"
