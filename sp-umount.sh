#!/bin/bash
set -ex

export SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. "${SCRIPT_PATH}/sp-common.sh"

parse_params $@

if [ ! -b "${IMG}" ]; then
  loopdev=`losetup -j "${IMG}" | cut -d " " -f1`
fi

sudo fuser -k "${WP}" || true
sudo umount -R "${WP}" || true
if [ ! -b "${IMG}" ]; then
  sudo losetup -d "${loopdev%?}"
fi
