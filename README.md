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
- `ripgrep`
- `rtk` installed under `/root/.local/bin`
- RTK Pi integration initialized at container startup if missing

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

## Test

Equivalent direct command:

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

## Run

Append the `pic` function to `~/.zshrc`:

```bash
printf '\npic() {\n  container run -it --memory 4g --ssh \\\n    --volume "$PWD:/workspace" \\\n    --volume "$HOME/.pi:/root/.pi" \\\n    --dns 1.1.1.1 \\\n    -w /workspace \\\n    pi-coding-node:24\n}\n' >> ~/.zshrc
```

Reload your shell:

```bash
source ~/.zshrc
```

Now, you can run `pic` in every directory and get a pi-agent sandboxed
