---
cairn: tasks
change: packages-hub
---

- [x] Scaffold: flake.nix with the tools, catalogue.toml (ortie, himalaya), README (what the hub is, the key fingerprint, the secrets), cairn spec/ and log/
- [x] Package script: download a release's Linux archives, fetch the tag's LICENSE files, map the archive to package paths (unknown entries fail), build the .deb and .rpm with nfpm for each architecture
- [x] APT repository: pool, Packages indexes, Release signed as InRelease and Release.gpg
- [x] DNF repository: rpm signatures, createrepo_c, repomd.xml.asc, pimalaya.repo
- [x] State: reuse the packages the live site already serves, build only new releases, keep the 3 latest per CLI
- [x] Stable releases only (maintainer, 2026-11-12): tags X.Y.Z from 1.0.0 on, no pre-release suffix, ranked by version; the formula takes the highest one too
- [x] Family licence only (maintainer, 2026-11-12): a release ships only when its Cargo.toml at the tag declares the catalogue's `MIT OR Apache-2.0`; licence and files move to the catalogue's top; a failing release listing or Cargo.toml fetch stops the run instead of dropping releases
- [x] Site: install page (APT with a deb822 source and Signed-By, DNF with pimalaya.repo, Homebrew, fingerprint), the public key exported from the signing key
- [x] Install tests against the locally served site in debian:stable, ubuntu:latest, fedora:latest and rockylinux:9 containers (Ubuntu images exclude /usr/share/doc, so the file check runs on Debian only); passed locally on 2026-11-11 with a throwaway key
- [ ] Pages deploy after the tests pass
- [ ] Homebrew: generate Formula/ortie.rb from the release archives and their SHA-256, without a `version` the strict audit calls redundant (done), install, test and audit it from a local tap on macos-15, macos-15-intel and ubuntu (done), push to pimalaya/homebrew-tap with TAP_DEPLOY_KEY; tap README (done)
- [x] Workflow: workflow_dispatch with a dry-run input, daily schedule, one run at a time, channels independent; green dry run on GitHub on 2026-11-11 (run 43100038134, real signing key)
- [ ] First real run by hand once the family releases are out (maintainer, 2026-11-12: wait for them), after the maintainer's go; the workflow stays disabled until then; check the install page commands on a real Debian and Fedora machine
- [ ] Land: fold the delta into spec/hub.md, spec/linux-repository.md and spec/homebrew-tap.md, write the log entry
