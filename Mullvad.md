# Mullvad Notes

This is a local troubleshooting note for Apple container networking when Mullvad
VPN is enabled.

## Observed Failure

With Mullvad connected, Apple containers can fail DNS and public outbound
networking even when `/usr/local/bin/container` is added to Mullvad split
tunneling.

Typical runtime failure:

```bash
container run --rm node:24-slim \
  /bin/bash -lc 'cat /etc/resolv.conf && apt-get update'
```

Observed output:

```text
nameserver 192.168.64.1
Temporary failure resolving 'deb.debian.org'
```

Using the router DNS directly can also fail while the VPN is active:

```bash
container run --rm --dns 192.168.1.254 node:24-slim \
  /bin/bash -lc 'cat /etc/resolv.conf && apt-get update'
```

Observed output:

```text
nameserver 192.168.1.254
Temporary failure resolving 'deb.debian.org'
```

## What Worked

Disconnect Mullvad, restart Apple container, then use the router DNS:

```bash
container system stop
container system start

container run --rm --dns 192.168.1.254 node:24-slim \
  /bin/bash -lc 'cat /etc/resolv.conf && apt-get update'
```

After that passed, a clean image rebuild also passed:

```bash
container build --no-cache --dns 192.168.1.254 -t pi-coding-node:24 .
```

## Split Tunneling Test

Mullvad was configured with split tunneling enabled and LAN sharing allowed.
Excluding only `/usr/local/bin/container` was not enough.

These Apple container helper paths were tested as additional exclusions:

```text
/usr/local/bin/container-apiserver
/usr/local/libexec/container/plugins/container-network-vmnet/bin/container-network-vmnet
/usr/local/libexec/container/plugins/container-core-images/bin/container-core-images
/usr/libexec/containermanagerd
/usr/libexec/containermanagerd_system
```

After restarting Apple container, DNS still failed. The helper exclusions were
removed again.

Current practical workaround: disconnect Mullvad for image builds or package
installs that need container internet access, then reconnect it for normal local
work.

## 2026-06-04 Retest With Mullvad Connected

Mullvad status during the test:

```text
Connected; relay ch-zrh-wg-503; features LAN Sharing, Quantum Resistance,
Split Tunneling.
```

Current split-tunnel exclusions include `/usr/local/bin/container`, `/usr/bin/curl`,
`/usr/bin/ssh`, `wg`, `wg-quick`, and the local Node binary. Excluding
`/usr/local/bin/container` still does not make direct public container egress work.

Host-side results while Mullvad is on:

```bash
curl -v --connect-timeout 5 http://172.31.221.1:8000/v1/models  # OK, 761 bytes
curl -v --connect-timeout 5 http://google.com                         # OK, 219 bytes
```

Container results using the `pic`-equivalent image/run shape with `--dns 1.1.1.1`:

```bash
container run --rm --dns 1.1.1.1 --entrypoint /bin/bash pi-coding-node:24 -lc \
  'cat /etc/resolv.conf; curl -v --connect-timeout 5 http://172.31.221.1:8000/v1/models; curl -v --connect-timeout 5 http://google.com'
```

Observed:

```text
nameserver 1.1.1.1
http://172.31.221.1:8000/v1/models  -> OK, HTTP 200, 761 bytes
http://google.com                   -> DNS timeout / curl exit 28
```

Retesting container DNS choices while Mullvad is on:

```text
default / 192.168.64.1 -> Could not resolve google.com
192.168.1.254          -> DNS timeout
8.8.8.8, 9.9.9.9, 1.1.1.1 -> DNS timeout
```

Direct public IP egress also timed out from the container:

```text
curl http://142.250.74.206 -H 'Host: google.com' -> connection timeout
curl --resolve cloudflare-dns.com:443:1.1.1.1 https://cloudflare-dns.com/dns-query?... -> connection timeout
```

So the problem is not only DNS. With Mullvad connected, Apple containers can
reach the host/container-side local network, but direct public egress from the
container VM is blocked. This explains why `172.31.221.1:8000` works while
`google.com` and public IPs do not.

Host interface observations:

```text
lo0       127.165.160.189  # Mullvad local DNS on host
utun4     172.31.221.2     # Mullvad tunnel address
bridge100 192.168.64.1     # Apple container bridge/gateway
```

A host HTTP proxy bound on the Apple container bridge works around both DNS and
public egress for HTTP/HTTPS clients, because the container only connects to the
host bridge IP and the host process resolves/connects externally:

```bash
# host side: run an HTTP/HTTPS proxy listening on 0.0.0.0:8888 or 192.168.64.1:8888

# container side:
HTTP_PROXY=http://192.168.64.1:8888 \
http_proxy=http://192.168.64.1:8888 \
  curl -v --connect-timeout 5 http://google.com

HTTPS_PROXY=http://192.168.64.1:8888 \
https_proxy=http://192.168.64.1:8888 \
  curl -v --connect-timeout 5 https://www.google.com
```

Tested with a temporary Python proxy on the host: both HTTP and HTTPS Google
requests succeeded through `192.168.64.1:8888`. Using `172.31.221.1:8888` did
not reach the host proxy; use `192.168.64.1`, the Apple container bridge address.

## DeepSeek / Pi 400 From Inside `pic`

Selecting the DeepSeek model in `pic` originally produced:

```text
400 terminated
```

A minimal curl from the container worked:

```bash
curl http://172.31.221.1:8000/v1/models
curl http://172.31.221.1:8000/v1/chat/completions -d '{small request}'
```

But Pi's real streaming request body from inside the container returned HTTP 400
when posted directly to `http://172.31.221.1:8000/v1/chat/completions`. The same
request posted from the host succeeded.

Current fix: use `pic-proxy`, which starts a project-local `proxy-chain` forward
proxy on the host bridge and launches the container with proxy environment
variables. This keeps host `~/.pi/agent/models.json` unchanged.

```bash
pic-proxy
```

Internally this uses:

```text
container -> http://192.168.64.1:8888 -> host proxy-chain -> original target
```

Verified from an Apple container with Mullvad connected:

```bash
PIC_PROXY_PORT=8890 node pic-proxy-runner.cjs --version
```

Result:

```text
[pic-proxy] proxy-chain listening on http://192.168.64.1:8890
0.78.0
[pic-proxy] stopping proxy-chain
```
