# Signing

sOnOs signs two things with one GPG key:

- the packages and the database of the `[sonos]` pacman repository, served from
  `https://son-os.github.io/repo/$arch`;
- the ISO, as a detached signature next to it (`sOnOs-<version>-x86_64.iso.sig`).

The private key stays on the maintainer's machine and, optionally, in a GitHub secret. It is
never committed. The public key is committed, in `packages/sonos-keyring/`, and ships to users
in the `sonos-keyring` package.

> [!WARNING]
> Never commit a private key or a passphrase, and never paste one into an issue, a pull request
> or a chat. If the private key leaks, see [Replacing the key](#replacing-the-key).

## 1. Create the key

Once, on your own machine:

```shell
gpg --quick-generate-key 'sOnOs Release Signing Key' ed25519 sign 2y
```

GnuPG asks for a passphrase; choose one and keep it in a password manager. The name has no
e-mail address on purpose: the key identifies the project, not a person.

Show the fingerprint, the 40 characters that identify the key:

```shell
gpg --list-secret-keys --with-fingerprint 'sOnOs Release Signing Key'
```

The examples below call it `<FINGERPRINT>` (written without spaces).

## 2. Back it up

```shell
gpg --armor --export-secret-keys <FINGERPRINT> > sonos-signing-key.private.asc
gpg --armor --gen-revoke <FINGERPRINT> > sonos-signing-key.revoke.asc
```

Keep both files offline, for example on a USB drive that is not the one you carry, and delete
them from the disk afterwards. Without the backup, a lost disk means a new key and a manual
step for every user.

## 3. Publish the `[sonos]` repository

With [sOnInstall](https://github.com/sOn-Os/sOnInstall) checked out next to this repository:

```shell
GPGKEY=<FINGERPRINT> scripts/publish-repo.sh
```

or `GPGKEY=<FINGERPRINT> scripts/publish-repo.sh -s <sOnInstall checkout> -o <output folder>`.

The script

1. exports the public key to `packages/sonos-keyring/sonos.gpg` and writes `sonos-trusted` and
   `sonos-revoked` next to it;
2. builds and signs `soninstall` and `sonos-keyring`;
3. creates the signed database and puts everything in `out/repo/x86_64/`.

It uploads nothing. Afterwards:

1. Commit the three files in `packages/sonos-keyring/` if they are new or changed. They hold
   public keys only.
2. The first time, create the public repository `sOn-Os/repo` on GitHub and turn on GitHub
   Pages for its default branch (Settings → Pages → Deploy from a branch, `/ (root)`).
3. Copy the contents of `out/repo/` (the `x86_64` folder and `.nojekyll`) into a checkout of
   `sOn-Os/repo`, commit and push.
4. Check that it is served:

   ```shell
   curl -sI https://son-os.github.io/repo/x86_64/sonos.db | head -n 1
   curl -sI https://son-os.github.io/repo/x86_64/sonos.db.sig | head -n 1
   ```

Run the script again for every new soninstall version. Each run replaces the packages in
`out/repo/x86_64/` with the new builds.

> [!IMPORTANT]
> An ISO built from the `sonos-signed-repo` branch reads this repository when the installer
> starts. Publish the repository **before** releasing such an ISO, or the installer stops with
> a database error.

## 4. Sign the ISO

By hand:

```shell
gpg --local-user <FINGERPRINT> --detach-sign sOnOs-<version>-x86_64.iso
```

This writes `sOnOs-<version>-x86_64.iso.sig`. Publish it next to the ISO.

Or let the workflow do it, with these repository secrets
(Settings → Secrets and variables → Actions → New repository secret):

| Secret | Value |
|---|---|
| `GPG_PRIVATE_KEY` | the whole output of `gpg --armor --export-secret-keys <FINGERPRINT>` |
| `GPG_PASSPHRASE` | the passphrase of the key |

Without `GPG_PRIVATE_KEY` the workflow skips signing. A secret on GitHub can be used by anyone
who can push a workflow to the repository, so signing by hand is the stricter choice.

## 5. SourceForge upload (optional)

The workflow uploads the ISO, its checksum and its signature to SourceForge when these exist:

| Kind | Name | Value |
|---|---|---|
| Secret | `SF_SSH_KEY` | a private SSH key made for this purpose only, without a passphrase: `ssh-keygen -t ed25519 -f sf_deploy -N ''` |
| Variable | `SF_USER` | your SourceForge user name |
| Variable | `SF_PROJECT` | the SourceForge project's short name (the part after `/projects/` in its address) |

Add the public half (`sf_deploy.pub`) to your SourceForge account under
Account Settings → SSH Settings, then delete both files from your disk. Files go to
`/home/frs/project/<SF_PROJECT>/<tag>/`. Without `SF_SSH_KEY` the step is skipped.

## How users verify

The ISO:

```shell
sha256sum -c sOnOs-<version>-x86_64.iso.sha256
gpg --verify sOnOs-<version>-x86_64.iso.sig sOnOs-<version>-x86_64.iso
```

`gpg --verify` needs the public key first: `gpg --import sonos.gpg`, with
[`sonos.gpg`](../packages/sonos-keyring/sonos.gpg) from this repository. The fingerprint that
`gpg` prints must match the one published in the README.

Packages: nothing to do. The ISO and installed systems have `sonos-keyring`, and pacman refuses
`[sonos]` packages and databases that are not signed by that key (`SigLevel = Required`).

## Using the signed repository on a machine without sonos-keyring

```shell
sudo pacman-key --add packages/sonos-keyring/sonos.gpg
sudo pacman-key --lsign-key <FINGERPRINT>
```

and in `/etc/pacman.conf`, above `[core]`:

```ini
[sonos]
SigLevel = Required
Server = https://son-os.github.io/repo/$arch
```

## Which pacman.conf is which

| File | Used by | `[sonos]` |
|---|---|---|
| `pacman.build.conf` | `mkarchiso`, only while building the ISO | a local, unsigned folder (`Optional TrustAll`) |
| `airootfs/etc/pacman.conf` (branch `sonos-signed-repo`) | the live ISO, and every installed system: soninstall copies it to the disk | the hosted repository, `SigLevel = Required` |

`TrustAll` appears in `pacman.build.conf` only. That file never reaches a user's machine.

## Replacing the key

When the key expires, is lost or leaks:

1. Create a new key (step 1) and back it up (step 2).
2. If the old key leaked: add its fingerprint as a line to `packages/sonos-keyring/sonos-revoked`.
3. Delete `packages/sonos-keyring/sonos-trusted`. `publish-repo.sh` refuses to replace a key
   silently; deleting the file is how you tell it the change is intended.
4. Raise `pkgver` in `packages/sonos-keyring/PKGBUILD` to today's date.
5. Run `publish-repo.sh` with the new key, publish, and update the secrets.

Installed systems trust only the old key, so they cannot verify the new `sonos-keyring` by
themselves. Announce the change, with the commands from
[the section above](#using-the-signed-repository-on-a-machine-without-sonos-keyring).
To extend an expiring key instead, which needs none of this: `gpg --quick-set-expire <FINGERPRINT> 2y`,
then run `publish-repo.sh` and publish.
