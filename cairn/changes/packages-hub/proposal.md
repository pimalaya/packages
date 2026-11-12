---
cairn: change
id: packages-hub
status: active
created: 2026-11-11
---

# The packages hub

## Why

The Pimalaya CLIs reach people through crates.io, Nix, install.sh and packages other people maintain, and each of those lags: on 2026-11-11, with ortie 2.3.0 released, the AUR carried ortie 2.2.0 and nixpkgs 2.1.0. Nothing serves Debian, Ubuntu, Fedora or RHEL, and Homebrew carries himalaya (core, 2.2.1) but not ortie. The release workflow already builds every CLI as a static musl binary for every target, so one place can turn those archives into packages for every distribution version at once, without building anything again.

## What

This repository becomes the hub that turns the CLIs' GitHub releases into packages, plus the site pkg.pimalaya.org (GitHub Pages, deployed by Actions):

- **Catalogue.** catalogue.toml lists each CLI, its repository and the channels it ships to: comodoro and ortie on APT, DNF and the Homebrew tap; himalaya on APT and DNF at its 3.0.0 release, since Homebrew core already carries it.
- **APT and DNF.** One signed repository of each at pkg.pimalaya.org, holding .deb and .rpm packages made with nfpm from the release archives (binary, man pages, completions, documentation, licences) for the 3 highest stable releases of each CLI that carry Linux archives (himalaya 2.2.0 carries none). Stable means tagged X.Y.Z with X of 1 or more, no pre-release suffix, and `MIT OR Apache-2.0` declared in the Cargo.toml of the tag: a CLI ships nothing before its 1.0.0, a tag like neverest's `v1.0.0-beta`, published without the pre-release flag, never ships, and neither do the releases before the family's move to MIT OR Apache-2.0 (ortie 1.x under AGPL-3.0-only, himalaya 1.x under MIT, comodoro 1.0.0 under AGPL-3.0-or-later), whose licence and files differ. A static binary needs one package per architecture, which serves every distribution version. Signing key `CE05 CD30 AD91 9CC1 7D62  A78C DF3D EA0C 9370 3421` (RSA 4096, no expiry, user ID `Pimalaya Packages <pimalaya.org@posteo.net>`): the public half is pimalaya.asc at the repository root, the private half is the `GPG_PRIVATE_KEY` secret and the `pimalaya/packages/gpg-key` pass entry. A run refuses a signing key whose fingerprint is not the one of pimalaya.asc.
- **Homebrew.** The hub writes Formula/<cli>.rb in pimalaya/homebrew-tap (`brew install pimalaya/tap/ortie`) from the prebuilt macOS (arm64, Intel) and Linux (x86_64, arm64) archives, pushing with the `TAP_DEPLOY_KEY` deploy key.
- **Runs.** A run starts from the daily schedule or by hand, where it is a dry run unless told otherwise, one at a time. The site carries manifest.txt, listing every package plus the signing key and a hash of the hub's own files: a run whose manifest matches the live one publishes nothing, and a change to the hub reaches the site on the next run. A package already published is downloaded from the live site and served again byte for byte; only new releases are built and signed. Bumping `revision` in catalogue.toml rebuilds every package.
- **Tests before publishing.** The built site is served to Debian, Ubuntu, Fedora and Rocky Linux containers, which add the repository with the install page's commands and install every package; the formula is installed and tested on macOS arm64, macOS Intel and Linux before the push. A channel that fails its test keeps what it had.

Each a later change: the release workflows notifying the hub (a job in the shared pimalaya/nix workflow and a token allowed to start this repository's workflow), checking release checksums and attestations once releases carry them, winget, the AUR, and the install sections of the CLIs' READMEs.

## Choices

- **Architectures.** Debian: amd64, arm64, i386, and armhf built from armv6l, because Raspberry Pi OS's armhf targets ARMv6 with VFP, where the armv7l binary would crash. RPM: x86_64, aarch64, i686, armv7hl. Neither armel nor an RPM ARMv6 package is served. A release missing one architecture's archive is packaged for the others, and every binary's ELF machine is checked against its architecture.
- **Layout.** One APT suite `stable` with component `main`, one DNF repository holding every architecture.
- **Paths.** Binary in /usr/bin, man pages in /usr/share/man/manN, completions in each shell's vendor directory, share/doc/<cli>/ in /usr/share/doc/<cli>/ (where ortie 3's welcome looks for config.sample.toml), JSON schemas in /usr/share/<cli>/schemas/, desktop entries in /usr/share/applications, the licence files of the release tag in /usr/share/doc/<cli>/. Both archive layouts are read: the flat one (share/man/, share/completions/) and the system one of himalaya 2.0.0 (share/man/man1/, share/bash-completion/, share/zsh/, share/fish/, share/applications/). An unknown entry in an archive fails the run, so a layout change cannot drop files silently.
- **Budget.** The Linux archives of one release weigh 12 MB (ortie 2.3.0) and 34 MB (himalaya 2.2.1); keeping 3 releases of both as .deb and .rpm stays near 300 MB, under the 1 GB Pages site limit.
- **Tooling.** Shell scripts run through this repository's flake (nfpm, apt-ftparchive, createrepo_c, gnupg, jq, yq), on GitHub's Ubuntu and macOS runners.
