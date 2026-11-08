#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: setup-gacp.sh [--os macos|windows]

Install the gacp Git add, commit, and push command in the selected shell
profile. If --os is omitted, the operating system is detected where possible;
otherwise an interactive selection is offered.
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

gacp_block=$(cat <<'EOF'
# >>> setup-scripts gacp >>>
gacp() {
    if [ "$#" -ne 1 ] || [ -z "$1" ]; then
        printf '%s\n' 'Usage: gacp <commit-message>' >&2
        return 2
    fi

    git add . && git commit -m "$1" && git push
}
# <<< setup-scripts gacp <<<
EOF
)

install_block() {
    config_file=$1
    block=$2
    start_marker=$3
    end_marker=$4
    tmp_file=
    filtered_file=

    mkdir -p "$(dirname "$config_file")"
    tmp_file=$(mktemp "${config_file}.tmp.XXXXXX")

    cleanup() {
        [ -z "$tmp_file" ] || rm -f "$tmp_file"
        [ -z "$filtered_file" ] || rm -f "$filtered_file"
    }
    trap cleanup 0
    trap 'exit 1' HUP INT TERM

    if [ -f "$config_file" ]; then
        marker_state=$(awk -v start="$start_marker" -v end="$end_marker" '
            $0 == start { if (inside) bad = 1; starts++; inside = 1; next }
            $0 == end { if (!inside) bad = 1; ends++; inside = 0; next }
            END {
                if (inside) bad = 1
                printf "%d:%d:%d\n", starts, ends, bad
            }
        ' "$config_file")

        case "$marker_state" in
            0:0:0)
                cp -p "$config_file" "$tmp_file"
                ;;
            1:1:0)
                filtered_file=$(mktemp "${config_file}.tmp.XXXXXX")
                awk -v start="$start_marker" -v end="$end_marker" '
                    $0 == start { inside = 1; next }
                    $0 == end { inside = 0; next }
                    !inside { print }
                ' "$config_file" > "$filtered_file"
                cp -p "$config_file" "$tmp_file"
                cat "$filtered_file" > "$tmp_file"
                rm -f "$filtered_file"
                filtered_file=
                ;;
            *)
                printf 'Error: found malformed or duplicate setup markers in %s; no changes made.\n' "$config_file" >&2
                return 1
                ;;
        esac
    fi

    if [ -s "$tmp_file" ]; then
        printf '\n' >> "$tmp_file"
    fi
    printf '%s\n' "$block" >> "$tmp_file"
    mv -f "$tmp_file" "$config_file"
    tmp_file=
    trap - 0 HUP INT TERM
}

case "$selected_os" in
    macos)
        config_file=${ZDOTDIR:-"$HOME"}/.zshrc
        install_block "$config_file" "$gacp_block" '# >>> setup-scripts gacp >>>' '# <<< setup-scripts gacp <<<'
        printf 'Installed gacp for macOS Zsh in %s\n' "$config_file"
        ;;
    windows)
        for config_file in "$HOME/.bashrc" "$HOME/.bash_profile"; do
            install_block "$config_file" "$gacp_block" '# >>> setup-scripts gacp >>>' '# <<< setup-scripts gacp <<<'
        done
        printf 'Installed gacp for Windows Bash in %s and %s\n' "$HOME/.bashrc" "$HOME/.bash_profile"
        ;;
esac

printf '%s\n' 'Open a new terminal or reload the profile, then run: gacp "my commit message"'
