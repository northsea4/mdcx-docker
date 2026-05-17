#!/bin/sh
#
# Initialize Linux users and groups, by (re)writing /etc/passwd, /etc/group and
# /etc/shadow.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

err() {
    echo "ERROR: $*" >&2
}

die() {
    err "$@"
    exit 1
}

get_content() {
    # https://man7.org/linux/man-pages/man2/access.2.html
    # If the calling process has appropriate privileges (i.e., is superuser),
    # POSIX.1-2001 permits an implementation to indicate success for an X_OK check
    # even if none of the execute file permission bits are set.
    if [ -x "$1" ] && ls -ld "$1" | grep -q '^-.*x'; then
        set +e
        val="$("$1")"
        rc="$?"
        set -e
        if [ "${rc}" -ne 0 ]; then
            err "$1 terminated with error ${rc}."
            exit 1
        fi
        printf "%s" "${val}"
    elif [ -f "$1" ]; then
        if [ "${2:-string}" = "boolean" ] && [ "$(stat -c "%s" "$1")" -eq 0 ]; then
            echo "1"
        else
            cat "$1"
        fi
    fi
}

user_id_valid() {
    case "$1" in
        '' | *[!0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

user_name_valid() {
    case "$1" in
        # Must start with `[a-z_]` and be followed by `[a-z0-9_-]`.
        '' | [a-z_][a-z0-9_-]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

user_id_exists() {
    [ -f /etc/passwd ] && cut -d':' -f3 < /etc/passwd | grep -q "^$1\$"
}

user_name_exists() {
    [ -f /etc/passwd ] && cut -d':' -f1 < /etc/passwd | grep -q "^$1\$"
}

group_id_valid() {
    user_id_valid "$@"
}

group_name_valid() {
    user_name_valid "$@"
}

group_id_exists() {
    [ -f /etc/group ] && cut -d':' -f3 < /etc/group | grep -q "^$1\$"
}

group_name_exists() {
    [ -f /etc/group ] && cut -d':' -f1 < /etc/group | grep -q "^$1\$"
}

get_group_name_from_group_id() {
    if [ -f /etc/group ]; then
        grep ":x:$1:" /etc/group | head -n1 | cut -d':' -f1
    fi
}

add_group() {
    duplicate_check=true
    if [ "$1" = "--allow-duplicate" ]; then
        duplicate_check=false
        shift
    fi

    name="$1"
    gid="$2"

    if ${duplicate_check} && group_id_exists "${gid}"; then
        err "group ID '${gid}' already exists."
        return 1
    elif ${duplicate_check} && group_name_exists "${name}"; then
        err "group '${name}' already exists."
        return 1
    fi

    echo "${name}:x:${gid}:" >> /etc/group
}

add_user() {
    duplicate_check=true
    if [ "$1" = "--allow-duplicate" ]; then
        duplicate_check=false
        shift
    fi

    name="$1"
    uid="$2"
    gid="$3"
    homedir="${4:-/dev/null}"

    if ${duplicate_check} && user_id_exists "${uid}"; then
        err "user ID '${uid}' already exists."
        return 1
    elif ${duplicate_check} && user_name_exists "${name}"; then
        err "user '${name}' already exists."
        return 1
    elif ! group_id_exists "${gid}"; then
        err "group ID '${gid}' doesn't exist."
        return 1
    fi

    # Add the user to '/etc/passwd'.
    echo "${name}::${uid}:${gid}::${homedir}:/sbin/nologin" >> /etc/passwd

    # Add a corresponding entry to '/etc/shadow'.
    echo "${name}:!::0:::::" >> /etc/shadow
}

add_user_to_group() {
    uname="$1"
    gname="$2"

    if ! user_name_exists "${uname}"; then
        err "user '${uname}' doesn't exists."
        exit 1
    elif ! group_name_exists "${gname}"; then
        err "group '${gname}' doesn't exists."
        exit 1
    fi

    if grep -q "^${gname}:.*:$" /etc/group; then
        sed-patch "/^${gname}:/ s/$/${uname}/" /etc/group
    else
        sed-patch "/^${gname}:/ s/$/,${uname}/" /etc/group
    fi
}

# Initialize files.
rm -f /etc/passwd /etc/group /etc/shadow
touch /etc/passwd /etc/group /etc/shadow

# Add defined groups.
if [ -d /etc/cont-groups.d ]; then
    find /etc/cont-groups.d -type d -mindepth 1 -maxdepth 1 | while read -r entry; do
        # Get attributes.
        name="$(basename "${entry}")"
        disabled="$(get_content "${entry}"/disabled boolean)"
        id="$(get_content "${entry}"/id)"

        if is-bool-val-true "${disabled:-0}"; then
            continue
        fi

        # Validate attributes.
        group_name_valid "${name}" || die "group name defined at ${entry} is not valid."
        group_id_valid "${id}" || die "group id defined at ${entry} is not valid."

        # Add group.
        add_group "${name}" "${id}"
    done
fi

# Add defined users.
if [ -d /etc/cont-users.d ]; then
    find /etc/cont-users.d -type d -mindepth 1 -maxdepth 1 | while read -r entry; do
        # Get attributes.
        name="$(basename "${entry}")"
        disabled="$(get_content "${entry}"/disabled boolean)"
        uid="$(get_content "${entry}"/id)"
        gid="$(get_content "${entry}"/gid)"
        home="$(get_content "${entry}"/home)"
        grps="$(get_content "${entry}"/grps)"

        if is-bool-val-true "${disabled:-0}"; then
            continue
        fi

        # Validate attributes.
        user_name_valid "${name}" || die "user name defined at ${entry} is not valid."
        user_id_valid "${uid}" || die "user id defined at ${entry} is not valid."
        group_id_valid "${gid}" || die "group id defined at ${entry} is not valid."

        # Add user.
        add_user "${name}" "${uid}" "${gid}" "${home}"
        printf "%s\n" "${grps}" | while read -r grp; do
            [ -n "${grp}" ] || continue
            group_name_valid "${grp}" || err "group name '${grp}' defined at ${entry} is not valid."
            add_user_to_group "${name}" "${grp}"
        done
    done
fi

# Add the 'app' user.
# NOTE: This user requires special handling, since its user/group ID is
#       configurable and may match an existing one.
add_group --allow-duplicate app "${GROUP_ID}"
add_user --allow-duplicate app "${USER_ID}" "${GROUP_ID}"
add_user_to_group app app

# Handle supplementary groups of user 'app'.
echo "${SUP_GROUP_IDS:-},${SUP_GROUP_IDS_INTERNAL:-}" \
    | tr ',' '\n' \
    | grep -v '^$' \
    | grep -v '^0$' \
    | grep -vw "${GROUP_ID}" \
    | sort -nub \
    | while read -r gid; do
        case "${gid}" in
            '' | *[!0-9]*)
                err "SUP_GROUP_IDS contains invalid groupd ID '${gid}'."
                exit 1
                ;;
        esac
        if ! group_id_exists "${gid}"; then
            add_group "grp${gid}" "${gid}"
            add_user_to_group app "grp${gid}"
        else
            add_user_to_group app "$(get_group_name_from_group_id "${gid}")"
        fi
    done

# Finally, set correct permissions on files.
chmod 644 /etc/passwd
chmod 644 /etc/group
chown root:shadow /etc/shadow
chmod 644 /etc/shadow

# vim:ft=sh:ts=4:sw=4:et:sts=4
