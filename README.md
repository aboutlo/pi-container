# pi-container

Run the Pi coding agent inside an Apple container while editing the current host
directory. The container gets the tools Pi needs, mounts the current directory as
`/workspace`, and keeps the normal non-containerized `pi` command untouched.

After setup, run this from any project directory:

```bash
pic
```

That starts a containerized Pi agent in the directory where you ran `pic`.

## Image Contents

The custom `node:24-trixie-slim` image includes:

- `@earendil-works/pi-coding-agent`
- `pnpm`
- `ripgrep`
- `rtk` installed under `/root/.local/bin`
- RTK Pi integration loaded from the mounted Pi config, or from the image fallback

## Requirements

- 26.x macOS with Apple container installed.
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

## Upgrade Pi

The Pi agent is installed into the image at build time. To upgrade it to the
latest published npm version, rebuild the image without cache:

```bash
container build --no-cache --dns 1.1.1.1 -t pi-coding-node:24 .
```

Verify the version:

```bash
container run --rm --entrypoint /bin/bash pi-coding-node:24 -lc 'pi --version'
```

The `pic` function uses the `pi-coding-node:24` tag, so it will use the upgraded
image after the rebuild.

## Test

Equivalent direct command:

```bash
container run -it --memory 4g \
  --volume "$PWD:/workspace" \
  --volume "$HOME/.pi:/root/.pi,readonly" \
  --dns 1.1.1.1 \
  -w /workspace \
  pi-coding-node:24 --session-dir /workspace/sessions
```

To start a shell instead of `pi`:

```bash
container run -it --memory 4g \
  --volume "$PWD:/workspace" \
  --volume "$HOME/.pi:/root/.pi,readonly" \
  --dns 1.1.1.1 \
  --entrypoint /bin/bash \
  -w /workspace \
  pi-coding-node:24
```

Smoke test inside the container:

```bash
node --version
npm --version
pnpm --version
rg --version
rtk --version
pi --help
```

RTK loads from `~/.pi` when the extension is already present. If `~/.pi` is
read-only and the extension is missing, the image loads its bundled RTK extension
instead.

## Run

Append the `pic` function to `~/.zshrc`:

```bash
printf '\npic() {\n  mkdir -p "$PWD/sessions"\n  container run -it --memory 4g \\\n    --volume "$PWD:/workspace" \\\n    --volume "$HOME/.pi:/root/.pi,readonly" \\\n    --dns 1.1.1.1 \\\n    -w /workspace \\\n    pi-coding-node:24 --session-dir /workspace/sessions\n}\n' >> ~/.zshrc
```

Reload your shell:

```bash
source ~/.zshrc
```

Now, you can run `pic` in any directory to start a containerized Pi agent for
that directory. The function creates `./sessions` for Pi session storage and
mounts your `~/.pi` config read-only.
