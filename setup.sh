#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: setup.sh [--os macos|windows]

Install the gscb, gacp, and k shell shortcuts in the selected shell profile.
If --os is omitted, the operating system is detected where possible; otherwise
an interactive selection is offered.
EOF
}

requested_os=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --os)
            if [ "$#" -lt 2 ]; then
                printf '%s\n' 'Error: --os requires macos or windows.' >&2
                exit 2
            fi
            requested_os=$2
            shift 2
            ;;
        --os=*)
            requested_os=${1#--os=}
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Error: unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$requested_os" in
    macos|windows)
        selected_os=$requested_os
        ;;
    '')
        system_name=$(uname -s 2>/dev/null || printf '%s' unknown)
        case "$system_name" in
            Darwin*)
                selected_os=macos
                ;;
            MINGW*|MSYS*|CYGWIN*)
                selected_os=windows
                ;;
            *)
                if [ ! -t 0 ]; then
                    printf '%s\n' 'Could not detect the OS in this shell. Re-run with --os macos or --os windows.' >&2
                    exit 2
                fi
                printf '%s\n' 'Select the OS whose shell profile should be configured:' '1) macOS (Zsh)' '2) Windows (Bash)'
                printf '%s' 'Enter 1 or 2: '
                IFS= read -r selection
                case "$selection" in
                    1) selected_os=macos ;;
                    2) selected_os=windows ;;
                    *)
                        printf '%s\n' 'Error: choose 1 for macOS or 2 for Windows.' >&2
                        exit 2
                        ;;
                esac
                ;;
        esac
        ;;
    *)
        printf 'Error: unsupported OS "%s". Choose macos or windows.\n' "$requested_os" >&2
        exit 2
        ;;
esac

install_profile() {
    config_file=$1
    tmp_file=
    filtered_file=

    mkdir -p "$(dirname "$config_file")"
    tmp_file=$(mktemp "${config_file}.tmp.XXXXXX")
    filtered_file=$(mktemp "${config_file}.tmp.XXXXXX")

    cleanup() {
        [ -z "$tmp_file" ] || rm -f "$tmp_file"
        [ -z "$filtered_file" ] || rm -f "$filtered_file"
    }
    trap cleanup 0
    trap 'exit 1' HUP INT TERM

    if [ -f "$config_file" ]; then
        if ! awk '
            BEGIN {
                starts["gscb"] = "# >>> setup-scripts gscb >>>"
                starts["gacp"] = "# >>> setup-scripts gacp >>>"
                starts["kubernetes"] = "# >>> setup-scripts kubernetes >>>"
                starts["shortcuts"] = "# >>> setup-scripts shortcuts >>>"
                ends["gscb"] = "# <<< setup-scripts gscb <<<"
                ends["gacp"] = "# <<< setup-scripts gacp <<<"
                ends["kubernetes"] = "# <<< setup-scripts kubernetes <<<"
                ends["shortcuts"] = "# <<< setup-scripts shortcuts <<<"
            }
            {
                marker_id = ""
                for (id in starts) {
                    if ($0 == starts[id] || $0 == ends[id]) {
                        marker_id = id
                        break
                    }
                }

                if (marker_id == "") {
                    if (!inside) print
                    next
                }

                if ($0 == starts[marker_id]) {
                    if (inside || seen[marker_id]) bad = 1
                    inside = marker_id
                    seen[marker_id] = 1
                    next
                }

                if (inside != marker_id) bad = 1
                inside = ""
                next
            }
            END {
                if (inside || bad) exit 1
            }
        ' "$config_file" > "$filtered_file"; then
            printf 'Error: found malformed or duplicate setup markers in %s; no changes made.\n' "$config_file" >&2
            return 1
        fi

        if [ -e "$config_file" ]; then
            cp -p "$config_file" "$tmp_file"
            cat "$filtered_file" > "$tmp_file"
        fi
    else
        : > "$tmp_file"
    fi

    install_gscb=1
    install_gacp=1
    install_k=1

    for shortcut in gscb gacp k; do
        case "$shortcut" in
            gscb)
                if grep -Eq '^[[:space:]]*(function[[:space:]]+)?gscb[[:space:]]*(\(\))?[[:space:]]*\{' "$filtered_file"; then
                    install_gscb=0
                fi
                ;;
            gacp)
                if grep -Eq '^[[:space:]]*(function[[:space:]]+)?gacp[[:space:]]*(\(\))?[[:space:]]*\{' "$filtered_file"; then
                    install_gacp=0
                fi
                ;;
            k)
                if grep -Eq '^[[:space:]]*alias[[:space:]]+k=' "$filtered_file"; then
                    install_k=0
                fi
                ;;
        esac

        case "$shortcut" in
            gscb) [ "$install_gscb" -eq 1 ] && printf 'Installing gscb in %s\n' "$config_file" || printf 'Skipping gscb; already configured in %s\n' "$config_file" ;;
            gacp) [ "$install_gacp" -eq 1 ] && printf 'Installing gacp in %s\n' "$config_file" || printf 'Skipping gacp; already configured in %s\n' "$config_file" ;;
            k) [ "$install_k" -eq 1 ] && printf 'Installing k=kubectl in %s\n' "$config_file" || printf 'Skipping k; already configured in %s\n' "$config_file" ;;
        esac
    done

    if [ "$install_gscb" -eq 0 ] && [ "$install_gacp" -eq 0 ] && [ "$install_k" -eq 0 ] && ! grep -Eq '^# >>> setup-scripts (gscb|gacp|kubernetes|shortcuts) >>>$' "$config_file"; then
        cleanup
        tmp_file=
        filtered_file=
        trap - 0 HUP INT TERM
        return 0
    fi

    if [ "$install_gscb" -eq 1 ] || [ "$install_gacp" -eq 1 ] || [ "$install_k" -eq 1 ]; then
        if [ -s "$tmp_file" ] && [ -n "$(tail -n 1 "$tmp_file")" ]; then
            printf '\n' >> "$tmp_file"
        fi
        printf '%s\n' '# >>> setup-scripts shortcuts >>>' >> "$tmp_file"

        if [ "$install_gscb" -eq 1 ]; then
            cat >> "$tmp_file" <<'EOF'
gscb() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        printf '%s\n' 'Usage: gscb <branch-name> [repository-path]' >&2
        return 2
    fi

    git -C "${2:-.}" switch -c "$1"
}
EOF
        fi

        if [ "$install_gacp" -eq 1 ]; then
            cat >> "$tmp_file" <<'EOF'
gacp() {
    if [ "$#" -ne 1 ] || [ -z "$1" ]; then
        printf '%s\n' 'Usage: gacp <commit-message>' >&2
        return 2
    fi

    git add . && git commit -m "$1" && git push
}
EOF
        fi

        if [ "$install_k" -eq 1 ]; then
            printf '%s\n' 'alias k=kubectl' >> "$tmp_file"
        fi

        printf '%s\n' '# <<< setup-scripts shortcuts <<<' >> "$tmp_file"
    fi

    if [ -f "$config_file" ] && cmp -s "$config_file" "$tmp_file"; then
        cleanup
        tmp_file=
        filtered_file=
        trap - 0 HUP INT TERM
        return 0
    fi

    mv -f "$tmp_file" "$config_file"
    tmp_file=
    cleanup
    filtered_file=
    trap - 0 HUP INT TERM
}

case "$selected_os" in
    macos)
        config_file=${ZDOTDIR:-"$HOME"}/.zshrc
        install_profile "$config_file"
        ;;
    windows)
        for config_file in "$HOME/.bashrc" "$HOME/.bash_profile"; do
            install_profile "$config_file"
        done
        ;;
esac

printf '%s\n' 'Open a new terminal or reload the profile. Shortcuts: gscb <branch-name> [repository-path], gacp "<commit-message>", and k <kubectl-arguments>.'
