#!/bin/bash
set -ex

export SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. "${SCRIPT_PATH}/sp-common.sh"

parse_params $@

if [ ! -d "$WP" ]; then mkdir "$WP"; fi

if [ -b "$IMG" ]; then
  parts=( "$IMG"1 "$IMG"2 )
else
  loopdev=( $(sudo losetup --find --show --partscan "$IMG") )
  parts=( "${loopdev}p1" "${loopdev}p2" )
fi

if [ -z "${USE_EXT4}" ]; then
  sudo mount ${parts[1]} "${WP}" "-ocompress=zstd:15,subvol=${SUBVOL}"
  sudo mount ${parts[1]} "${WP}/mnt/fs_root" "-osubvolid=0"
else
  sudo mount ${parts[1]} "${WP}"
fi

sudo mount ${parts[0]} "${WP}/boot"

for dir in dev proc sys; do
  [ -d "${WP}/${dir}" ] || sudo mkdir "${WP}/${dir}"
  sudo mount --bind /"${dir}" "${WP}/${dir}"
done

for dir in run tmp; do
  [ -d "${WP}/${dir}" ] || sudo mkdir "${WP}/${dir}"
  sudo mount none "${WP}/${dir}" -t tmpfs
done

[ -d "${WP}/build" ] && [ -d "${BUILDDIR}" ] && sudo mount --bind "${BUILDDIR}" "${WP}/build"
[ -d "$WP/var/cache/pacman" ] && [ -d "${CACHE}" ] && sudo mount --bind "${CACHE}" "${WP}/var/cache/pacman"

[ -d "${WP}/run/systemd/resolve" ] || sudo mkdir -p "${WP}/run/systemd/resolve"
[ -f "${WP}/run/systemd/resolve/resolv.conf" ] || sudo cp -L /etc/resolv.conf "${WP}/run/systemd/resolve/"
