---
cairn: delta
change: packages-hub
---

## ADDED Requirements

Capability `hub`:

### Requirement: A catalogue of CLIs and channels
The repository SHALL list in catalogue.toml each CLI it packages: its GitHub repository, its one-line description and the channels it ships to. Ortie ships to `apt`, `dnf` and `homebrew`, himalaya to `apt` and `dnf`. The catalogue SHALL also set the family licence, `MIT OR Apache-2.0`, and its files, LICENSE-MIT and LICENSE-APACHE. The hub SHALL never touch a CLI or a channel the catalogue does not list.

### Requirement: Packages come from the release archives
A run SHALL package the `<cli>.<system>.tgz` archives of the CLI's stable GitHub releases and SHALL build nothing from source. A stable release is published, not a draft nor a pre-release, tagged `X.Y.Z` or `vX.Y.Z` with X of 1 or more, and its Cargo.toml at the tag declares exactly the catalogue's licence: 0.x versions, suffixed tags like `v1.0.0-beta` and releases under another licence never ship, and each skipped release is logged with its licence. Releases rank by version, not by date. The licence files SHALL come from the CLI's repository at the release tag. A release list or a Cargo.toml that cannot be fetched SHALL fail the run rather than leave releases out.

#### Scenario: A CLI before 1.0
- **WHEN** a catalogued CLI has only 0.x releases
- **THEN** no channel ships it, and its first release from 1.0.0 on ships at the next run

#### Scenario: A release under another licence
- **GIVEN** comodoro 1.0.0 declaring `AGPL-3.0-or-later` and comodoro 2.0.0 declaring `MIT OR Apache-2.0`
- **WHEN** a run plans comodoro
- **THEN** only 2.0.0 ships, and the log names 1.0.0's licence

### Requirement: Runs converge
A run SHALL make every channel of every catalogued CLI match its highest stable releases, whether it was started by the daily schedule or by hand through `workflow_dispatch`. Runs SHALL go one at a time. The site SHALL carry manifest.txt, listing the signing key's fingerprint, a hash of the hub's files and every package path; a run whose manifest matches the live one SHALL publish nothing to the site, and a run whose formula matches the tap's SHALL push nothing.

#### Scenario: A release nobody announced
- GIVEN ortie 3.0.0 released and no run started since
- WHEN the daily run starts
- THEN ortie 3.0.0 reaches the APT and DNF repositories and the tap

### Requirement: Dry run
A run started by hand SHALL be a dry run unless its `dry-run` input is turned off. A dry run SHALL build and test every channel, current or not, and publish nothing.

### Requirement: Nothing untested is published
The site and the tap SHALL each be published only after their own install tests passed. A failing channel SHALL keep what it published before and SHALL NOT stop the other from publishing.

### Requirement: Secrets
`GPG_PRIVATE_KEY` (the signing key) and `TAP_DEPLOY_KEY` (write access to pimalaya/homebrew-tap only) SHALL be this repository's secrets and SHALL appear in no log and no published file.

Capability `linux-repository`:

### Requirement: The site
pkg.pimalaya.org SHALL be served by GitHub Pages from this repository's workflow, over HTTPS only, and SHALL carry an install page, the public key as pimalaya.asc, the DNF repository file pimalaya.repo, manifest.txt, the APT repository under apt/ and the DNF repository under rpm/.

### Requirement: Signed with one key
Every APT index, every RPM package and every DNF index SHALL be signed with the key of pimalaya.asc, `CE05 CD30 AD91 9CC1 7D62  A78C DF3D EA0C 9370 3421`, which the site serves as pimalaya.asc and the install page names by fingerprint; a run SHALL refuse any other key. The APT suite SHALL carry InRelease and Release.gpg, the DNF repository repodata/repomd.xml.asc, and pimalaya.repo SHALL set `gpgcheck=1` and `repo_gpgcheck=1`.

### Requirement: One package per architecture
Each of the 3 highest stable releases carrying Linux archives SHALL become one .deb per Debian architecture and one .rpm per RPM architecture, serving every distribution version: amd64 and x86_64 from x86_64-linux, arm64 and aarch64 from aarch64-linux, i386 and i686 from i686-linux, armhf from armv6l-linux, armv7hl from armv7l-linux. A missing archive SHALL leave its packages out, and a binary whose ELF machine is not its architecture's SHALL fail the run. A package SHALL depend on no other package.

### Requirement: Package contents
A package SHALL install the binary in /usr/bin, the man pages in /usr/share/man/manN/, the bash, zsh and fish completions in the distribution's vendor directory for each shell, share/doc/<cli>/ in /usr/share/doc/<cli>/, share/schemas/ in /usr/share/<cli>/schemas/, share/applications/ in /usr/share/applications/, and the licence files in /usr/share/doc/<cli>/. The flat archive layout (share/man/, share/completions/) and the system one (share/man/man1/, share/bash-completion/completions/, share/zsh/site-functions/, share/fish/vendor_completions.d/) SHALL both be read, the elvish and PowerShell completions left out, and any other entry SHALL fail the run.

#### Scenario: Ortie's sample configuration
- GIVEN the ortie 3.0.0 archive holding share/doc/ortie/config.sample.toml
- WHEN its .deb is installed on Debian
- THEN /usr/share/doc/ortie/config.sample.toml exists, where the welcome of /usr/bin/ortie copies it from

### Requirement: Packages are never rebuilt
A package already published SHALL be served again byte for byte, never rebuilt nor re-signed, until `revision` in catalogue.toml changes, which renames and rebuilds every package.

### Requirement: Install test
Before the site is deployed, a run SHALL serve the built site to Debian stable, Ubuntu LTS, Fedora and Rocky Linux 9 containers, add the repository there with the install page's commands, install every catalogued CLI and run `<cli> --version`, failing on any signature or install error. Where the image keeps documentation (Debian), every file of every installed package SHALL exist.

Capability `homebrew-tap`:

### Requirement: One formula per catalogued CLI
For each CLI shipping to `homebrew`, the hub SHALL write Formula/<cli>.rb in pimalaya/homebrew-tap, so `brew install pimalaya/tap/<cli>` installs the highest stable release carrying the aarch64-darwin, x86_64-darwin, aarch64-linux and x86_64-linux archives, each pinned by its SHA-256. The formula SHALL install the binary, the man pages, the bash, zsh and fish completions, the JSON schemas in its pkgshare and share/doc/<cli>/ in its doc directory, and its test SHALL check that `<cli> --version` prints the version.

### Requirement: Tested before pushed
The hub SHALL install, test and audit a formula on macOS arm64, macOS Intel and Linux before pushing it, and SHALL push to the tap with `TAP_DEPLOY_KEY` only.
