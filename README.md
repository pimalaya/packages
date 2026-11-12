# Pimalaya packages

The hub turning the GitHub releases of the Pimalaya CLIs into packages: the signed APT and DNF repositories of [pkg.pimalaya.org](https://pkg.pimalaya.org), where the install instructions are, and the formulae of [pimalaya/homebrew-tap](https://github.com/pimalaya/homebrew-tap).

## How it works

- [catalogue.toml](catalogue.toml) lists the CLIs and the channels each ships to.
- The [Hub workflow](.github/workflows/hub.yml) runs every day and by hand, where it is a dry run unless the `dry-run` box is unticked. Each run makes every channel match the highest stable releases (X.Y.Z from 1.0.0 on, no pre-release, under the catalogue's licence `MIT OR Apache-2.0`) and publishes nothing when they already do.
- [scripts/linux-build](scripts/linux-build) packages the static binaries of the release archives with nfpm, signs the repositories and writes the site; [scripts/linux-test](scripts/linux-test) installs every package in Debian, Ubuntu, Fedora and Rocky Linux containers before the deploy.
- [scripts/formula](scripts/formula) writes the Homebrew formulae, installed and tested on macOS and Linux before the push to the tap.

The full behaviour is specified in [cairn/](cairn).

## Signing key

[pimalaya.asc](pimalaya.asc), fingerprint `CE05 CD30 AD91 9CC1 7D62  A78C DF3D EA0C 9370 3421`, user ID `Pimalaya Packages <pimalaya.org@posteo.net>`. The build refuses any other key.

## Secrets

- `GPG_PRIVATE_KEY`: the armored signing key, no passphrase.
- `TAP_DEPLOY_KEY`: the SSH deploy key with write access to pimalaya/homebrew-tap.

## Local use

```sh
nix develop --command ./scripts/linux-build out/site
nix develop --command ./scripts/linux-test out/site
nix develop --command ./scripts/formula out
```

`linux-build` reads the signing key from `GPG_PRIVATE_KEY`; set `HUB_TEST_KEY=1` to build with a throwaway key, and `FORCE=true` to build even when the live site is current. `linux-test` needs Docker.
