#!/usr/bin/env bash
set -euo pipefail

cd /usr/local
git clone https://github.com/kingluo/burl
ln -sf /usr/local/burl/burl /usr/local/bin

install_deps() {
    for dep in "$@"; do
        if !which $1 &>/dev/null; then
            if grep 'ID_LIKE=debian' /etc/os-release &>/dev/null; then
                apt -y install $dep
            else
                echo "$dep not found."
                echo "Please install them manually later."
            fi
        fi
    done
}

install_deps jo jq

if ! curl --version | grep http3 &>/dev/null; then
    echo "current curl version doesn't support http3."
    read -p "Compile the latest version? [y/N]: " ok
    if [[ "$ok" == "Y" ]]; then
        tmpdir=$(mktemp -d)
        trap "rm -rf $tmpdir" EXIT QUIT TERM
        cd $tmpdir

        git clone https://github.com/wolfSSL/wolfssl.git
        cd wolfssl
        autoreconf -fi
        ./configure --enable-quic --enable-session-ticket --enable-earlydata --enable-psk --enable-harden --enable-altcertchains
        make install
        cd $tmpdir

        git clone -b v0.13.0 https://github.com/ngtcp2/nghttp3
        cd nghttp3
        autoreconf -fi
        ./configure --enable-lib-only
        make install
        cd $tmpdir

        git clone -b v0.17.0 https://github.com/ngtcp2/ngtcp2
        cd ngtcp2
        autoreconf -fi
        ./configure --enable-lib-only --with-wolfssl
        make install
        cd $tmpdir

        git clone https://github.com/curl/curl
        cd curl
        autoreconf -fi
        ./configure --with-wolfssl=/usr/local --with-nghttp3=/usr/local --with-ngtcp2=/usr/local
        make install
    fi
fi

echo ";-) Done."
