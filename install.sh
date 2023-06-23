#!/usr/bin/env bash

set -euo pipefail

log() {
	>&2 echo "${@:-UNKNOWN MESSAGE}"
}

die() {
	log "FATAL: ${@:-UNKNOWN FATAL ERROR}"
	exit 1
}

[ -z "${DEBUG+x}" ] || { >&2 echo "DEBUG environment variable is set. Enabling debugging output."; set -x; }

path="$(dirname "$(realpath "${0}")")" || die "Could not determine path of executable."

[ -d "${path}/users" ] || die "No \"users\" file under \"${path}\"."

IFS=$'\n' read -d '' -r -a users <<< "$(find ./users -mindepth 1 -maxdepth 1 -type f | sed 's/.*\///')" || true
[ "${#users[@]}" > "0" ] || die "No users specified in this repository. Aborting."

for u in "${users[@]}"; do
	useradd -m -U -G wheel,adm,systemd-journal "${u}"
	homedir="$(getent passwd "${u}" | cut -d: -f 6)"
	mkdir "${homedir}/.ssh"
	cat "${path}/users/${u}" > "${homedir}/.ssh/authorized_keys"
	chown -R "${u}:${u}" "${homedir}/.ssh"
	chmod 700 "${homedir}/.ssh"
	chmod 600 "${homedir}/.ssh/authorized_keys"
done

read -r -a oldusers <<< $(awk -F: '$3>=1000&&$1!="nfsnobody"{print $1}' /etc/passwd | tr '\n' ' ')
for u in "${oldusers[@]}"; do
	[ ! -f "${path}/users/${u}" ] || continue
	#userdel -r "${u}" || true
done
