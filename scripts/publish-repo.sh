#!/usr/bin/env bash
# Builds the signed [sonos] package repository and stages it in a local folder.
#
#   GPGKEY=<fingerprint> scripts/publish-repo.sh [-s <sOnInstall checkout>] [-o <output folder>]
#
# It builds soninstall (from the sOnInstall checkout) and every package in packages/
# (sonos-keyring, sonos-ananicy-rules, sonos-settings) with "makepkg --sign",
# creates the repository database with "repo-add --sign", and leaves everything in
# <output folder>/x86_64, laid out for https://son-os.github.io/repo/$arch.
#
# It does not push or upload anything. Copy the output into the sOn-Os/repo GitHub Pages
# repository and push that yourself. docs/signing.md has the whole procedure.
#
# Run it as a regular user: makepkg does not build as root, and uses sudo only to install
# missing build dependencies.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEYRING_DIR=$ROOT/packages/sonos-keyring
SONINSTALL_DIR=${SONINSTALL_DIR:-$ROOT/../sOnInstall}
OUT_DIR=$ROOT/out/repo
ARCH=x86_64

usage() {
	sed -n '2,14s/^# \{0,1\}//p' "$0"
}

die() {
	printf 'publish-repo: %s\n' "$*" >&2
	exit 1
}

while getopts 's:o:h' option; do
	case $option in
		s) SONINSTALL_DIR=$OPTARG ;;
		o) OUT_DIR=$OPTARG ;;
		h) usage; exit 0 ;;
		*) usage >&2; exit 1 ;;
	esac
done

(( EUID != 0 )) || die 'run this as a regular user, makepkg does not build packages as root'
[[ -n ${GPGKEY:-} ]] || die 'set GPGKEY to the fingerprint of the signing key, see docs/signing.md'

for tool in git gpg makepkg repo-add; do
	command -v "$tool" >/dev/null || die "$tool is not installed"
done

[[ -f $SONINSTALL_DIR/packaging/local/PKGBUILD ]] \
	|| die "no sOnInstall checkout at $SONINSTALL_DIR, pass it with -s"
SONINSTALL_DIR=$(cd "$SONINSTALL_DIR" && pwd)

gpg --batch --list-secret-keys "$GPGKEY" >/dev/null 2>&1 \
	|| die "there is no secret key for $GPGKEY in your GnuPG keyring"
FINGERPRINT=$(gpg --batch --with-colons --fingerprint "$GPGKEY" | awk -F: '$1 == "fpr" { print $10; exit }')
[[ -n $FINGERPRINT ]] || die "could not read the fingerprint of $GPGKEY"

# The keyring package ships the public key and marks it as trusted. Both files are public
# and belong in git. A different key already in place is never replaced silently.
if [[ -s $KEYRING_DIR/sonos-trusted ]]; then
	grep -q "^$FINGERPRINT:" "$KEYRING_DIR/sonos-trusted" \
		|| die "packages/sonos-keyring/sonos-trusted names another key than $FINGERPRINT. Changing the signing key is a deliberate step: see docs/signing.md."
else
	printf '%s:4:\n' "$FINGERPRINT" > "$KEYRING_DIR/sonos-trusted"
fi
gpg --batch --export "$FINGERPRINT" > "$KEYRING_DIR/sonos.gpg"
[[ -e $KEYRING_DIR/sonos-revoked ]] || : > "$KEYRING_DIR/sonos-revoked"

WORK_DIR=$(mktemp -d)
SONINSTALL_PKGBUILD=$SONINSTALL_DIR/packaging/local/PKGBUILD
cp -- "$SONINSTALL_PKGBUILD" "$WORK_DIR/PKGBUILD.soninstall"

cleanup() {
	# makepkg writes the version it computed back into the PKGBUILD; leave the checkout as it was
	cp -- "$WORK_DIR/PKGBUILD.soninstall" "$SONINSTALL_PKGBUILD"
	rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$WORK_DIR/packages"

build() {
	local dir=$1
	shift
	(cd "$dir" && PKGDEST=$WORK_DIR/packages makepkg --sign --key "$FINGERPRINT" \
		--force --clean --cleanbuild --noconfirm "$@")
}

build "$SONINSTALL_DIR/packaging/local" --syncdeps --needed
# These only install files and depend on each other, which a build machine without
# [sonos] cannot resolve, so their dependencies are not checked
for package_dir in "$ROOT"/packages/*/; do
	build "$package_dir" --nodeps
done

# The repository holds one build of each package: the new one
STAGE_DIR=$OUT_DIR/$ARCH
mkdir -p "$STAGE_DIR"
STAGE_DIR=$(cd "$STAGE_DIR" && pwd)
find "$STAGE_DIR" -maxdepth 1 \( -name '*.pkg.tar.zst' -o -name '*.pkg.tar.zst.sig' -o -name 'sonos.db*' -o -name 'sonos.files*' \) -delete
cp -- "$WORK_DIR"/packages/*.pkg.tar.zst "$WORK_DIR"/packages/*.pkg.tar.zst.sig "$STAGE_DIR/"

repo-add --sign --key "$FINGERPRINT" "$STAGE_DIR/sonos.db.tar.gz" "$STAGE_DIR"/*.pkg.tar.zst

# repo-add makes sonos.db and sonos.files symlinks to the archives. A static host serves
# files, so they become copies.
while IFS= read -r -d '' link; do
	cp --remove-destination -- "$(readlink -f -- "$link")" "$link"
done < <(find "$STAGE_DIR" -maxdepth 1 -type l -print0)
find "$STAGE_DIR" -maxdepth 1 -name '*.old' -delete

# GitHub Pages runs Jekyll on a repository unless this file is there
: > "$OUT_DIR/.nojekyll"

for signature in "$STAGE_DIR"/*.sig; do
	gpg --batch --verify "$signature" "${signature%.sig}" 2>/dev/null \
		|| die "the signature ${signature##*/} does not verify"
done

cat <<EOF

The signed [sonos] repository is in $OUT_DIR:
$(cd "$OUT_DIR" && find . -type f | sort | sed 's/^/  /')

Signed with $FINGERPRINT.

Nothing has been uploaded. To publish it:
  1. Commit packages/sonos-keyring/sonos.gpg, sonos-trusted and sonos-revoked in this
     repository if they are new or changed (they hold public keys only).
  2. Copy the contents of $OUT_DIR into your checkout of the sOn-Os/repo
     GitHub Pages repository, commit and push.
  3. It is then served at https://son-os.github.io/repo/$ARCH
EOF
