#!/bin/sh
#
# Persists system configuration and state according to the list of files and
# directories in /etc/persist.conf. 
#
# The files and rerectories are first copied to the configured persistent
# configuration directory if they are not already present there, and then the
# originals are replaced by symlinks to the copies in the persistent
# configuration directory.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

[ -f /SAFEMODE ] && exit 0

CONFDIR="%CONFDIR%"
CONFLIST="/etc/persist.conf"

# Return the relative path of a file/dir within some ancestor.
#
# Arguments:
#
#   path:     absolute path
#   ancestor: absolute ancestor path
#
# The ancestor path can be left off to obtain a path relative to the root
# directory without the leading slash.
relpath() {
    path="$1"
    ancestor="$2"
    echo "${path##$ancestor/}"
}

# Create a persisten copy of a path in the $PERSISTENT directory and symlink
# the original to the persistent copy.
#
# Argument:
#   path:   absoolute path
#
# If the path is a symlink, the symlink target is persisted instead.
persist_path() {
  path="$1"
  while [ -L "$path" ]; do
    # Follow links until we reach a non-link file
    path="$(readlink "$path")"
  done
  [ -e "$path" ] || return 1
  relp="$(relpath "$path")"
  target_path="${CONFDIR}/$relp"
  target_dir="$(dirname "$target_path")"
  if [ ! -e "$target_path" ]; then
    mkdir -p "$target_dir" || return 1
    cp -Ra "$path" "$target_path" || return 1
  fi
  rm -rf "$path" || return 1
  ln -s "$target_path" "$path" || return 1
}

# This flag will be turned non-zero for any paths that fail to persist, and
# then used as a return code for the entire script.
errors=0

while read -r conf_path; do
  [ -e "$conf_path" ] || continue
  persist_path "$conf_path" || errors=1
done < "$CONFLIST"

# Make sure there's no shadow+ file in the persistent storage as this can 
# sometimes happen when power is lost right after setting a password and 
# subsequently disable setting passwords.
rm "${CONFDIR}/etc/shadow+" 2>/dev/null || true

exit $errors
