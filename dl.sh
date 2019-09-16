#!/usr/bin/env bash

set -e

declare -a deps
deps+=('SDL,https://www.libsdl.org/release/SDL2-2.0.10.tar.gz,fb31312ea1d4b45db839796ae2336dfe3d5884e5')
deps+=('SDL_image_compact,https://github.com/FNA-XNA/SDL_image_compact/archive/master.tar.gz,ANY')
deps+=('MojoShader,https://github.com/FNA-XNA/MojoShader/archive/fna.tar.gz,ANY')
deps+=('FAudio,https://github.com/FNA-XNA/FAudio/archive/19.09.tar.gz,a1e5377b27bb70bbe1ba4ea8fd6a5befa91e74d2')
deps+=('Theorafile,https://github.com/FNA-XNA/Theorafile/archive/master.tar.gz,ANY')
deps+=('MonoKickstart,https://github.com/flibitijibibo/MonoKickstart/archive/master.tar.gz,ANY')
deps+=('Mono,https://download.mono-project.com/sources/mono/mono-6.0.0.334.tar.xz,8b4ce69c2168a7c38bc1a4156ab12e13c61a71c6')
deps+=('FNA,https://github.com/FNA-XNA/FNA/archive/19.09.tar.gz,70dc4c2e74ec0ca08a34b660f9ef8f80348b21cc')

root="$(pwd)"

download() {
	for i in "${deps[@]}"; do
		IFS=',' read -a dep <<< "$i"
		name="${dep[0]}"
		url="${dep[1]}"
		hashA="${dep[2]}"
		filename="${url%/download}"
		bname="$name-$(basename "$filename")"
		case "$filename" in
		*.zip)
			mkdir -p "dl"
			hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
			if [ ! -f "dl/$bname" ] || [ "$hashA" != "$hashB" ]; then
				echo "Downloading $name from $url"
				curl --progress-bar -L "$url" -o "dl/$bname"
				hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
				if [ "$hashA" != "$hashB" ] && [ "$hashA" != "ANY" ]; then
					echo "Hashes doesn't match!" "$hashA" "$hashB"
					exit 1
				fi
			else
				echo "$name is up to date"
			fi
			;;

		*.tar|*.tar.gz|*.tar.xz|*.tar.bz2|*.tgz)
			mkdir -p "dl"
			hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
			if [ ! -f "dl/$bname" ] || [ "$hashA" != "$hashB" ]; then
				echo "Downloading $name from $url"
				curl --progress-bar -L "$url" -o "dl/$bname"
				hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
				if [ "$hashA" != "$hashB" ] && [ "$hashA" != "ANY" ]; then
					echo "Hashes doesn't match!" "$hashA" "$hashB"
					exit 1
				fi
			else
				echo "$name is up to date"
			fi
			;;

		*)
			mkdir -p deps
			hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
			if [ ! -f "dl/$bname" ] || [ "$hashA" != "$hashB" ]; then
				echo "Downloading $name from $url"
				curl --progress-bar -L "$url" -o "dl/$name"
				hashB="$(sha1sum "dl/$bname" 2> /dev/null | awk '{print $1}')"
				if [ "$hashA" != "$hashB" ]; then
					echo "Hashes doesn't match!" "$hashA" "$hashB"
					exit 1
				fi
			else
				echo "$name is up to date"
			fi
			;;
		esac
	done
}

extract() {
	outdir="$1"

	for i in "${deps[@]}"; do
		IFS=',' read -a dep <<< "$i"
		name="${dep[0]}"
		url="${dep[1]}"
		hashA="${dep[2]}"
		filename="${url%/download}"
		bname="$name-$(basename "$filename")"
		case "$filename" in
		*.zip)
			mkdir -p "$outdir/$name.tmp"
			echo "Extracting $name"
			unzip -q "dl/$bname" -d "$outdir/$name.tmp"
			# rm "dl/$bname"
			rm -rf "$outdir/$name"
			mkdir -p "$outdir/$name"
			mv "$outdir/$name.tmp/"* "$outdir/$name"
			rmdir "$outdir/$name.tmp"
			if [ -f "patches/$name.patch" ]; then
				(cd "$outdir/$name" && patch -s -p1 < "$root/patches/$name.patch")
			fi
			;;

		*.tar|*.tar.gz|*.tar.xz|*.tar.bz2|*.tgz)
			case "$filename" in
			*xz)	compressor=J ;;
			*bz2)	compressor=j ;;
			*gz)	compressor=z ;;
			*tgz)	compressor=z ;;
			*)	compressor= ;;
			esac
			echo -n "Extracting $name"
			rm -rf "$outdir/$name"
			mkdir -p "$outdir/$name"
			tar -x${compressor}f "dl/$bname" -C "$outdir/$name" --strip-components=1 --checkpoint=.10000
			echo
			if [ -f "patches/$name.patch" ]; then
				(cd "$outdir/$name" && patch -s -p1 < "$root/patches/$name.patch")
			fi
			;;

		*)
			echo "Extracting $name"
			install -v -p -D -t "$outdir" "dl/$name"
			if [ -f "patches/$name.patch" ]; then
				(cd "$outdir" && patch -s < "$root/patches/$name.patch")
			fi
			;;
		esac
	done
}

if [ "$1" != "--extract" ]; then
	download
else
	extract "${2:-deps}"
fi
