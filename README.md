# pi-container

Custom `node:24-trixie-slim` image with:

- `@earendil-works/pi-coding-agent`
- `ripgrep`
- `rtk` installed under `/root/.local/bin`
- RTK Pi integration initialized at container startup

## Requirements

- macOS with Apple container installed.
- Apple container system services started.

Install Apple container by downloading the latest release asset from:

https://github.com/apple/container/releases

After installing, start the container system:

```bash
container system start
```

Build:

```bash
container build --dns 1.1.1.1 -t pi-coding-node:24 .
```

If Apple `container build` fails with `Temporary failure resolving 'deb.debian.org'`,
the long-running `buildkit` helper may be using the wrong resolver. Repair it with:

```bash
container exec buildkit /bin/sh -lc 'printf "nameserver 1.1.1.1\n" > /etc/resolv.conf'
```

Then rerun the build command.

Run:

```bash
container run -it --memory 4g --ssh \
  --volume "$PWD:/workspace" \
  --volume "$HOME/.pi:/root/.pi" \
  --dns 1.1.1.1 \
  -w /workspace \
  pi-coding-node:24
```

To start a shell instead of `pi`:

```bash
container run -it --memory 4g --ssh \
  --volume "$PWD:/workspace" \
  --volume "$HOME/.pi:/root/.pi" \
  --dns 1.1.1.1 \
  --entrypoint /bin/bash \
  -w /workspace \
  pi-coding-node:24
```

Smoke test inside the container:

```bash
node --version
npm --version
rg --version
rtk --version
pi --help
```

RTK setup runs automatically before `pi` starts if the Pi extension is not already present.
