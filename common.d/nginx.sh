nginx_stop() {
    if [[ -f ${NGX_TMP}/logs/nginx.pid ]]; then
        ${NGINX_BIN:-nginx} -s stop -p ${NGX_TMP}
        sleep 1
        tail -10 ${NGX_TMP}/logs/error.log
        rm -rf ${NGX_TMP}
    fi
}

START_NGX() {
    NGX_TMP=$(mktemp -d)
    mkdir -p ${NGX_TMP}/{conf,logs}
    GC nginx_stop

    printf "${NGX_CONF_TEMPLATE}" \
        "${NGX_CONF_MAIN:-}" "${NGX_CONF_HTTP:-}" "${NGX_CONF:-}" \
        | sed -e "s@{{BURL_ROOT}}@${BURL_ROOT}@g" \
        > ${NGX_TMP}/conf/nginx.conf
    ${NGINX_BIN:-nginx} -p ${NGX_TMP} -c ${NGX_TMP}/conf/nginx.conf
    sleep 1
    [[ -f ${NGX_TMP}/logs/nginx.pid ]]
    tail -10 ${NGX_TMP}/logs/error.log
}

SET NGX_CONF_TEMPLATE <<'EOF'
events {}

%s

http {
    %s

    server {
        listen 0.0.0.0:80 default_server reuseport;
        listen [::]:80 default_server reuseport;
        listen 0.0.0.0:443 ssl default_server http2 reuseport;
        listen [::]:443 ssl default_server http2 reuseport;
        listen 0.0.0.0:443 quic reuseport;
        listen [::]:443 quic reuseport;

        ssl_certificate      {{BURL_ROOT}}/examples/certs/server.crt;
        ssl_certificate_key  {{BURL_ROOT}}/examples/certs/server.key;

        %s
    }
}
EOF
