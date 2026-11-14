# Releasing sOnOs

A checklist, in order. Replace `<version>` with the ISO's version, e.g. `2026.11.13`, and
`<tag>` with the git tag, e.g. `v2026.11.13`.

The ISO's version is the date of the build (`iso_version` in `profiledef.sh`), not the tag.
Tag and build on the same day so they match.

## Before the first release

- [ ] The signing key exists and is backed up ([signing.md](signing.md), steps 1 and 2).
- [ ] The SourceForge project exists, and the site and README link to it (search both for `TODO`).
- [ ] Optional: the secrets and variables for signing and the SourceForge upload are set
      ([signing.md](signing.md), steps 4 and 5).

## Every release

### 1. Packages

- [ ] sOnInstall's default branch has what the release should ship.
- [ ] If the ISO uses the hosted `[sonos]` repository (branch `sonos-signed-repo` is merged):
      run `GPGKEY=<FINGERPRINT> scripts/publish-repo.sh`, push the result to `sOn-Os/repo`, and
      check that `https://son-os.github.io/repo/x86_64/sonos.db` answers. **This comes before
      the ISO**: the installer on the ISO stops if the repository is missing.

### 2. Build

- [ ] Tag and push: `git tag <tag> && git push origin <tag>`.
- [ ] Wait for the **Build ISO** workflow. It builds the ISO, writes the checksum, creates the
      GitHub Release and keeps the ISO as a workflow artifact for 14 days.
- [ ] Or build on your own machine with the steps in the [README](../README.md#building-the-iso),
      then `sha256sum sOnOs-<version>-x86_64.iso > sOnOs-<version>-x86_64.iso.sha256`.

### 3. Test

- [ ] Download the ISO (the workflow artifact) and check it: `sha256sum -c sOnOs-<version>-x86_64.iso.sha256`.
- [ ] Boot it in a virtual machine, install with the default answers, and boot the installed system.
- [ ] On the installed system, `sudo pacman -Syu` finishes without signature errors.

### 4. Sign

- [ ] If the workflow did not sign it: `gpg --local-user <FINGERPRINT> --detach-sign sOnOs-<version>-x86_64.iso`.
- [ ] `gpg --verify sOnOs-<version>-x86_64.iso.sig sOnOs-<version>-x86_64.iso` says "Good signature".

### 5. Upload

The ISO is over GitHub's 2 GiB limit for release files, so the Release carries only the
checksum and the signature.

- [ ] GitHub Release: has `.iso.sha256` and `.iso.sig`. Add the signature by hand if you signed by hand.
- [ ] SourceForge: the ISO, `.iso.sha256` and `.iso.sig` are in the folder `<tag>` (the workflow
      uploads them when `SF_SSH_KEY` is set), and the ISO is marked as the default download.
- [ ] Google Drive mirror: upload the ISO, share it with "anyone with the link", and note the link.
- [ ] Download from each place once and run `sha256sum -c` on what you got.

### 6. Site

In `index.html` of [sOn-Os.github.io](https://github.com/sOn-Os/sOn-Os.github.io), as its README describes:

- [ ] the release line: version and size;
- [ ] the SHA256 box: the real checksum, and the file name in the `sha256sum -c` line;
- [ ] the Google Drive link, if the file changed;
- [ ] new screenshots in `screenshots/`, if the desktop looks different.

### 7. Announce

- [ ] Edit the GitHub Release notes: what changed since the last release.
- [ ] Post in [Discussions](https://github.com/sOn-Os/sOnOs/discussions) (Announcements).
- [ ] Update the README here if the download links or the fingerprint changed.
