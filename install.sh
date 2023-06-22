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

path="$(realpath "${0}")" || die "Could not determine path of executable."

[ -d "${path}/usrs" ] || die "No \"users\" file under \"${path}\"."

read -r -a users <<< "$(find ./users -mindepth 1 -maxdepth 1 -type f -exec basename {} \;)"
[ "${#users[@]}" > "0" ] || die "No users specified in this repository. Aborting."

read -r -a oldusers <<< $(awk -F: '$3>=1000&&$1!="nfsnobody"{print $1}' /etc/passwd | tr '\n' ' ')
for u in "${oldusers[@]}"; do
	[ ! -f "${path}/users/${u}" ] || continue
	userdel -r "${u}" || true
done

for u in "${users[@]}"; do
	useradd -m -U -G wheel,adm "${user}"
	mkdir ~"${u}/.ssh"
	cat "${path}/users/${u}" > ~"${u}"/.ssh/authorized_keys
	chown -R "${u}:${u}" ~"${u}/.ssh"
	chmod 700 ~"${u}/.ssh"
	chmod 600 ~"${u}/.ssh/authorized_keys"
done
