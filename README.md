# burl: bash + curl

A simple but flexible HTTP/3 testing framework based on bash and curl.

## Design

## Synopsis

## Examples

## Common Functions

### REQ()

The curl wrapper function works similarly to the curl command, except that it saves the response headers and body into two temporary files for later use.
You can apply any [curl options](https://curl.se/docs/manpage.html) to it.

### HEADER()

grep wrapper to validate current response headers (`${CURL_RSP_HEADERS}`).

### BODY()

grep wrapper to validate current response headers (`${CURL_RSP_BODY}`).

### JQ()

[jq](https://jqlang.github.io/jq/) wrapper to validate current response headers (`${CURL_RSP_BODY}`).

### GC()

Put a code snippet or function into the global gc list so that it is executed at the end of the current test file execution, for example to clean up temporary files.

You can execute GC() multiple times to add multiple code snippets or functions.

```bash
# code snippet
GC "rm -f ${my_temp_files}"

# customized gc function
GC my_gc_func
```

### START_NGX()

Render the nginx.conf and start nginx. Assume you set the conf related variables.

### ADMIN()

Configure APISIX via admin API, which is simple curl wrapper, so you can apply any curl options to it.

### XML()

Parse and validate the XML response body (`${CURL_RSP_BODY}`).

### SOAP()

Execute SOAP operation on remote web service and validate the output via jq expression.

### SET()

Assign here-doc text to variable.

```bash
SET NGX_CONF <<'EOF'
location / {
    add_header Alt-Svc 'h3=":443"; ma=86400';
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host "nghttp2.org";
    proxy_pass https://test_backend;
}
EOF
```

### TEST()

echo the test case title.

## Global Variables

### BURL_ROOT

The root path of burl installation, i.e `/usr/local/burl`

### TEST_HOST

curl host, only set when you need to test the origin server directly.

default value: `localhost`.

### TEST_PORT

curl port, only set when you need to test the origin server directly.

default value: `443`.

### TEST_SCHEME

curl scehme, only set when you need to test the origin server directly.

default value: `https`.

### CURL_RSP_HEADERS

the file that contains the current response headers content, which will be changed after next `REQ()`.

### CURL_RSP_BODY

the file that contains the current response headers body content, which will be changed after next `REQ()`.

### NGX_CONF_MAIN

nginx main configuration directives, used by `START_NGX()`.

### NGX_CONF_HTTP

nginx http configuration directives, used by `START_NGX()`.

### NGX_CONF

nginx location configuration directives of the default server (80 and 443, including HTTP/3), used by `START_NGX()`.
