#!/bin/sh
# Installs Lumen for the current user, without root. On Linux: the app in
# ~/.local/lumen.app, the lumen command in ~/.local/bin, and its entry
# in the applications menu.
# Made by mygo build.
#
#   sh install.sh [ARCHIVE]
#   sh install.sh --uninstall
set -eu

app_name='Lumen'
name='lumen'
# The commands in ~/.local/bin that run the app (linux.command), if any,
# separated by spaces.
command_names='lumen'
version='0.1.1'
# Where the manifests of the latest version are, with updates: in the
# release of the newest tag with the prefix when the repository's releases
# (api) hold others too.
releases=''

usage() {
	cat <<EOF
Usage: sh install.sh [ARCHIVE | --uninstall]

Installs $app_name for you. On Linux, in ~/.local: ARCHIVE, else
$name-$version-<platform>.tar.gz next to this script.
--uninstall removes it, and leaves its settings and data in place.
EOF
}

fail() {
	echo "install.sh: $*" >&2
	exit 1
}

fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$1"
	else
		wget -qO- "$1"
	fi
}

main() {
	if [ $# -gt 1 ]; then
		usage >&2
		exit 2
	fi
	case "${1:-}" in
	-h | --help)
		usage
		return
		;;
	--uninstall) ;;
	-*)
		usage >&2
		exit 2
		;;
	esac
	linux "$@"
}

linux() {
	app_dir="$HOME/.local/$name.app"
	bin_dir="$HOME/.local/bin"
	data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
	desktop_file="$data_home/applications/$name.desktop"
	mime_file="$data_home/mime/packages/$name.xml"
	if [ "${1:-}" = --uninstall ]; then
		uninstall
		return
	fi

	[ "$(uname -s)" = Linux ] || fail "$app_name installs on Linux"
	[ "$(id -u)" != 0 ] || fail "run this as the user to install $app_name for, not as root"
	# The desktop entry holds the path, which these characters would break.
	[ "$(printf '%s' "$app_dir" | tr -d '"$%\\\140\n')" = "$app_dir" ] ||
		fail "cannot install in $app_dir: the path has characters a desktop entry cannot hold"
	case "$(uname -m)" in
	x86_64 | amd64) target=linux-amd64 ;;
	aarch64 | arm64) target=linux-arm64 ;;
	*) fail "$app_name is not made for $(uname -m)" ;;
	esac

	work="$(mktemp -d)"
	staging="$HOME/.local/.$name.app.install"
	trap 'rm -rf "$work" "$staging"' EXIT
	trap 'exit 1' HUP INT TERM

	archive="${1:-}"
	if [ -z "$archive" ] && [ -f "$0" ] && [ -f "$(dirname -- "$0")/$name-$version-$target.tar.gz" ]; then
		archive="$(dirname -- "$0")/$name-$version-$target.tar.gz"
	fi
	if [ -z "$archive" ]; then
		[ -n "$releases" ] || fail "no $name-$version-$target.tar.gz next to this script: pass the archive to install"
	fi
	[ -f "$archive" ] || fail "no archive at $archive"
	tar -tzf "$archive" >"$work/names" 2>/dev/null || fail "$archive is not a .tar.gz archive"
	if grep -Eq '^/|(^|/)\.\.(/|$)' "$work/names"; then
		fail "$archive holds files outside the app"
	fi

	echo "Installing $app_name in $app_dir"
	rm -rf "$staging"
	mkdir -p "$staging"
	tar -xzf "$archive" -C "$staging"
	[ -f "$staging/$name" ] && [ -x "$staging/$name" ] || fail "$archive is not $app_name: it holds no $name"
	# Replace the app as a whole, so that no file of another version stays.
	rm -rf "$app_dir"
	mv "$staging" "$app_dir"

	mkdir -p "$data_home/applications"
	# Earlier install scripts linked a command named after the app. Links of
	# other names an earlier version had stay, as one the user made would:
	# --uninstall removes them.
	case " $command_names " in
	*" $name "*) ;;
	*) if ours "$bin_dir/$name"; then rm -f "$bin_dir/$name"; fi ;;
	esac
	run=
	for command_name in $command_names; do
		bin_link="$bin_dir/$command_name"
		if { [ -e "$bin_link" ] || [ -L "$bin_link" ]; } && ! ours "$bin_link"; then
			echo "Leaving $bin_link alone: it is not $app_name's" >&2
		else
			mkdir -p "$bin_dir"
			ln -sf "$app_dir/$name" "$bin_link"
			# The app runs by the first command linked.
			if [ -z "$run" ]; then
				run=$bin_link
				if [ "$(command -v "$command_name" || true)" = "$bin_link" ]; then
					run=$command_name
				fi
			fi
		fi
	done
	# The entry of the app, running it and showing its icon by their paths,
	# which updates of the app register again the same way.
	if [ -f "$app_dir/$name.desktop" ]; then
		while IFS= read -r line || [ -n "$line" ]; do
			case "$line" in
			"Exec=$name" | "Exec=$name "*) line="Exec=\"$app_dir/$name\"${line#"Exec=$name"}" ;;
			"Icon=$name") if [ -f "$app_dir/$name.png" ]; then line="Icon=$app_dir/$name.png"; fi ;;
			esac
			printf '%s\n' "$line"
		done <"$app_dir/$name.desktop" >"$desktop_file"
	fi
	if [ -f "$app_dir/$name.xml" ]; then
		mkdir -p "$data_home/mime/packages"
		cp "$app_dir/$name.xml" "$mime_file"
	else
		rm -f "$mime_file"
	fi
	update_databases

	if [ -n "$run" ]; then
		echo "Installed $app_name: open it from the applications menu, or run $run"
	else
		echo "Installed $app_name: open it from the applications menu"
	fi
	if ! has_webkit; then
		echo "$app_name needs WebKitGTK, which is not installed. Install it with:" >&2
		echo "  $(webkit_install_command)" >&2
	fi
}

# has_webkit fails when the system's library cache has no WebKitGTK, which
# the app loads when it starts (4.1, else 4.0), with GTK, which it depends
# on. It succeeds when it cannot tell, as without ldconfig (NixOS) or a
# cache (musl).
has_webkit() {
	for ldconfig in "$(command -v ldconfig || true)" /sbin/ldconfig /usr/sbin/ldconfig; do
		[ -n "$ldconfig" ] && [ -x "$ldconfig" ] || continue
		"$ldconfig" -p >"$work/libs" 2>/dev/null || return 0
		grep -qF libc.so.6 "$work/libs" || return 0
		grep -qF -e libwebkit2gtk-4.1.so.0 -e libwebkit2gtk-4.0.so.37 "$work/libs"
		return
	done
	return 0
}

webkit_install_command() {
	distro=
	for file in /etc/os-release /usr/lib/os-release; do
		if [ -f "$file" ]; then
			distro="$(. "$file" && echo "${ID:-} ${ID_LIKE:-}")" || true
			break
		fi
	done
	for id in $distro; do
		case "$id" in
		debian | ubuntu) echo "sudo apt install libwebkit2gtk-4.1-0" && return ;;
		fedora) echo "sudo dnf install webkit2gtk4.1" && return ;;
		arch) echo "sudo pacman -S webkit2gtk-4.1" && return ;;
		opensuse* | suse) echo "sudo zypper install libwebkit2gtk-4_1-0" && return ;;
		esac
	done
	echo "the package manager of your system (the library is libwebkit2gtk-4.1.so.0)"
}

uninstall() {
	[ -d "$app_dir" ] || fail "$app_name is not installed in $app_dir"
	# Only what install.sh and the app made: a package of the system may
	# install the same names. Links of names the app no longer has go too.
	for link in "$bin_dir"/*; do
		if ours "$link"; then
			rm -f "$link"
		fi
	done
	if [ -f "$desktop_file" ] && grep -qF "$app_dir/" "$desktop_file"; then
		rm -f "$desktop_file" "$mime_file"
	fi
	for entry in "$data_home"/applications/*.url-handler.desktop; do
		if [ -f "$entry" ] && grep -qF "$app_dir/" "$entry"; then
			rm -f "$entry"
		fi
	done
	rm -rf "$app_dir"
	update_databases
	echo "Uninstalled $app_name. Its settings and data are still in place."
}

# ours tells whether $1 is the link to the app that install.sh makes.
ours() {
	[ -L "$1" ] && [ "$(readlink "$1")" = "$app_dir/$name" ]
}

update_databases() {
	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database "$data_home/applications" >/dev/null 2>&1 || true
	fi
	if [ -d "$data_home/mime/packages" ] && command -v update-mime-database >/dev/null 2>&1; then
		update-mime-database "$data_home/mime" >/dev/null 2>&1 || true
	fi
}

main "$@"
