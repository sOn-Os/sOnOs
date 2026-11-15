#!/usr/bin/env bash
# Builds the unsigned [sonos] repository that mkarchiso installs from (pacman.build.conf).
#
#   scripts/build-local-repo.sh [-s <sOnInstall checkout>] [<repository folder>]
#
# The repository folder defaults to /var/tmp/sonos-repo, the path in pacman.build.conf.
# It holds soninstall, built by sOnInstall's packaging/local/build-repo.sh, and sonos-keyring
# once the public signing key is in packages/sonos-keyring (see docs/signing.md).
#
# Run it as a regular user: makepkg does not build as root, and uses sudo only to install
# missing build dependencies.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEYRING_DIR=$ROOT/packages/sonos-keyring
SONINSTALL_DIR=${SONINSTALL_DIR:-$ROOT/../sOnInstall}

usage() {
	sed -n '2,11s/^# \{0,1\}//p' "$0"
}

die() {
	printf 'build-local-repo: %s\n' "$*" >&2
	exit 1
}

while getopts 's:h' option; do
	case $option in
		s) SONINSTALL_DIR=$OPTARG ;;
		h) usage; exit 0 ;;
		*) usage >&2; exit 1 ;;
	esac
done
shift $((OPTIND - 1))

(( EUID != 0 )) || die 'run this as a regular user, makepkg does not build packages as root'
[[ -x $SONINSTALL_DIR/packaging/local/build-repo.sh ]] \
	|| die "no sOnInstall checkout at $SONINSTALL_DIR, pass it with -s"

mkdir -p "${1:-/var/tmp/sonos-repo}"
REPO_DIR=$(cd "${1:-/var/tmp/sonos-repo}" && pwd)

"$SONINSTALL_DIR/packaging/local/build-repo.sh" "$REPO_DIR"

if [[ -s $KEYRING_DIR/sonos.gpg ]]; then
	rm -f "$REPO_DIR"/sonos-keyring-*.pkg.tar.zst
	(cd "$KEYRING_DIR" && PKGDEST=$REPO_DIR makepkg --force --clean --cleanbuild --noconfirm)
	repo-add --quiet "$REPO_DIR/sonos.db.tar.gz" "$REPO_DIR"/sonos-keyring-*.pkg.tar.zst
	echo "sonos-keyring is in the [sonos] repository at $REPO_DIR"
else
	echo 'sonos-keyring was not built: packages/sonos-keyring/sonos.gpg is not there yet (docs/signing.md)'
fi
