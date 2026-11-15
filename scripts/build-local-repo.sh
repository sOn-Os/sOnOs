#!/usr/bin/env bash
# Builds the unsigned [sonos] repository that mkarchiso installs from (pacman.build.conf).
#
#   scripts/build-local-repo.sh [-s <sOnInstall checkout>] [<repository folder>]
#
# The repository folder defaults to /var/tmp/sonos-repo, the path in pacman.build.conf.
# It holds soninstall, built by sOnInstall's packaging/local/build-repo.sh, and the packages
# in packages/; sonos-keyring only once the public signing key is in packages/sonos-keyring
# (see docs/signing.md).
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

for package_dir in "$ROOT"/packages/*/; do
	name=$(basename "$package_dir")
	if [[ $name == sonos-keyring && ! -s $KEYRING_DIR/sonos.gpg ]]; then
		echo 'sonos-keyring was not built: packages/sonos-keyring/sonos.gpg is not there yet (docs/signing.md)'
		continue
	fi
	rm -f "$REPO_DIR/$name"-[0-9]*.pkg.tar.zst
	# These only install files and depend on each other, which a machine without [sonos]
	# cannot resolve, so their dependencies are not checked
	(cd "$package_dir" && PKGDEST=$REPO_DIR makepkg --nodeps --force --clean --cleanbuild --noconfirm)
	repo-add --quiet "$REPO_DIR/sonos.db.tar.gz" "$REPO_DIR/$name"-[0-9]*.pkg.tar.zst
	echo "$name is in the [sonos] repository at $REPO_DIR"
done
