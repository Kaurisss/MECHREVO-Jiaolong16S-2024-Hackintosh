#!/bin/sh
(
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
umask 077

main() {
    check_environment
    choose_volume
    read_account
    check_target
    confirm_setup

    trap 'echo "STOP: setup was not completed. Check the error above before rebooting or running again."' 0
    b="$d/private/var/db/setup-skip-$(date +%Y%m%d-%H%M%S)"
    mkdir "$b"
    cp -p "$db/groups/admin.plist" "$b/admin.plist"
    printf 'BACKUP: %s\n' "$b"

    g=$(uuidgen)
    dc -create "$u" UserShell /bin/zsh
    dc -create "$u" RealName "$realname"
    dc -create "$u" UniqueID 501
    dc -create "$u" PrimaryGroupID 20
    dc -create "$u" GeneratedUID "$g"
    dc -create "$u" NFSHomeDirectory "/Users/$username"
    echo 'At New Password, enter your own non-empty login password; input is hidden.'
    dc -passwd "$u"
    /usr/libexec/PlistBuddy -c 'Print :ShadowHashData:0' "$db/users/$username.plist" >/dev/null
    dc -merge /Local/Target/Groups/admin GroupMembership "$username"
    dc -merge /Local/Target/Groups/admin GroupMembers "$g"
    mkdir -m 700 "$d/Users/$username"
    touch "$d/Users/$username/.skipbuddy"
    chown -R 501:20 "$d/Users/$username"

    touch "$b/.AppleSetupDone"
    chmod 400 "$b/.AppleSetupDone"
    mv "$b/.AppleSetupDone" "$d/private/var/db/.AppleSetupDone"
    sync
    trap - 0
    printf 'DONE: reboot into the installed macOS and log in as %s.\n' "$username"
}

check_environment() {
    [ "$(uname -s)" = Darwin ] || fail 'Run this script in macOS Recovery Terminal.'
    [ "$(id -u)" = 0 ] || fail 'Run as root in macOS Recovery Terminal.'
}

choose_volume() {
    set --
    for volume in /Volumes/*; do
        if [ -d "$volume/private/var/db/dslocal/nodes/Default/users" ] &&
           [ -f "$volume/private/var/db/dslocal/nodes/Default/groups/admin.plist" ]; then
            set -- "$@" "$volume"
        fi
    done
    [ "$#" -gt 0 ] || fail 'No initialized macOS data volume found. Boot the installed macOS once until Setup Assistant stalls, then return to Recovery and mount/unlock its data volume.'

    echo 'Select the installed macOS data volume:'
    index=1
    for volume do
        printf '%s. %s\n' "$index" "$volume"
        index=$((index + 1))
    done
    while :; do
        printf 'Volume number: '
        IFS= read -r choice || exit 1
        index=1
        for volume do
            if [ "$choice" = "$index" ]; then
                d=$volume
                return
            fi
            index=$((index + 1))
        done
        echo 'Enter a number from the list.'
    done
}

read_account() {
    while :; do
        printf 'Username (start with a-z; then a-z, 0-9, _ or -): '
        IFS= read -r username || exit 1
        case "$username" in
            ''|[!a-z]*|*[!a-z0-9_-]*)
                echo 'Invalid username.' ;;
            *) break ;;
        esac
    done
    printf 'Display name [%s]: ' "$username"
    IFS= read -r realname || exit 1
    realname=${realname:-$username}
}

check_target() {
    db="$d/private/var/db/dslocal/nodes/Default"
    u="/Local/Target/Users/$username"
    [ ! -e "$d/private/var/db/.AppleSetupDone" ] || fail 'Setup Assistant is already marked complete on this volume.'
    [ ! -e "$db/users/$username.plist" ] || fail 'This username already exists. Choose another username.'
    [ ! -e "$d/Users/$username" ] || fail 'This home directory already exists. Choose another username.'
    used=$(dc -search /Local/Target/Users UniqueID 501)
    [ -z "$used" ] || fail 'UID 501 is already in use. This script requires a fresh installation.'
}

confirm_setup() {
    printf '\nData volume: %s\nUsername: %s\nDisplay name: %s\nUID: 501\nHome: /Users/%s\n' \
        "$d" "$username" "$realname" "$username"
    printf 'Type YES to create this administrator and skip Setup Assistant: '
    IFS= read -r confirmation || exit 1
    if [ "$confirmation" != YES ]; then
        echo 'Cancelled. No changes made.'
        exit 0
    fi
}

dc() {
    dscl -f "$db" localonly "$@"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

main
)
