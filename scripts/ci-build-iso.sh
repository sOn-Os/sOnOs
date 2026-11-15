#!/usr/bin/env bash
# Builds the ISO inside a fresh archlinux container. The workflow in
# .github/workflows/build-iso.yml runs it; on your own machine use the steps in README.md.
#
#   docker run --rm --privileged -v "$PWD:/work" archlinux:latest /work/sOnOs/scripts/ci-build-iso.sh
#
# It expects this profile and a sOnInstall checkout next to each other (../sOnInstall, or
# SONINSTALL_DIR), runs as root, and writes the ISO to out/ in the profile.
set -euo pipefail

PROFILE=$(cd "$(dirname "$0")/.." && pwd)
SONINSTALL_DIR=${SONINSTALL_DIR:-$PROFILE/../sOnInstall}
BUILD_USER=builder
BUILD_HOME=/home/$BUILD_USER

(( EUID == 0 )) || { echo 'ci-build-iso: this runs as root inside the build container' >&2; exit 1; }
[[ -d $SONINSTALL_DIR/packaging/local ]] \
	|| { echo "ci-build-iso: no sOnInstall checkout at $SONINSTALL_DIR" >&2; exit 1; }

pacman -Syu --noconfirm --needed archiso base-devel git sudo

# makepkg refuses to run as root, so the packages are built by a throwaway user on copies
# of the checkouts: the mounted ones belong to the runner's user.
useradd --create-home "$BUILD_USER"
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$BUILD_USER" > "/etc/sudoers.d/$BUILD_USER"
cp -r -- "$PROFILE" "$BUILD_HOME/sOnOs"
cp -r -- "$SONINSTALL_DIR" "$BUILD_HOME/sOnInstall"
rm -rf -- "$BUILD_HOME/sOnOs/out" "$BUILD_HOME/sOnOs/work"
chown -R "$BUILD_USER:$BUILD_USER" "$BUILD_HOME"

install -d -o "$BUILD_USER" -g "$BUILD_USER" /var/tmp/sonos-repo
sudo -u "$BUILD_USER" "$BUILD_HOME/sOnOs/scripts/build-local-repo.sh" \
	-s "$BUILD_HOME/sOnInstall" /var/tmp/sonos-repo

df -h /
mkarchiso -v -r -w /var/tmp/sonos-work -o "$PROFILE/out" "$PROFILE"
ls -l "$PROFILE/out"
