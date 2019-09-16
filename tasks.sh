#!/usr/bin/env bash

set -eo pipefail


root="$(pwd)"

arch=$(uname -m)

SRC="$root/sources"
PREFIX="$root/prefix"
OUTPUT="$root/output"
if [ "$OSTYPE" == "darwin" ]; then
	LIBROOT="$OUTPUT/osx"
else
	if [ "$arch" == "x86_64" ]; then
		LIBROOT="$OUTPUT/lib64"
	elif [ "$arch" == "aarch64" ]; then
		LIBROOT="$OUTPUT/libaarch64"
	elif [ "$arch" == "armv7l" ]; then
		LIBROOT="$OUTPUT/libarmhf"
	elif [ "$arch" == "i686" ]; then
		LIBROOT="$OUTPUT/lib"
	else
		LIBROOT="$OUTPUT/unknown-$arch"
	fi
fi
PRECOMPILED="$OUTPUT"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export PATH="$PREFIX/bin:$PATH"

makearg="-j$(nproc)"


task_clean_prefix() {
	tput setaf 2 && tput bold
	echo "==> Cleaning prefix"
	tput sgr0
	rm -rf "$PREFIX"
	mkdir -p $PREFIX/{etc,bin,include,lib}
}

task_sdl() {
	tput setaf 2 && tput bold
	echo "==> Building SDL"
	tput sgr0
	cd "$SRC/SDL"

	rm -rf build
	mkdir -p build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX:PATH="$PREFIX" -DCMAKE_BUILD_TYPE=Release -DCLOCK_GETTIME=ON -DSNDIO=OFF -DRPATH=OFF -DSDL_STATIC=OFF
	make $makearg
	make install
	install -v -p -D -t "$LIBROOT" "$PREFIX/lib/libSDL2-2.0.so.0"
}

task_sdl_image_compact() {
	tput setaf 2 && tput bold
	echo "==> Building SDL_image_compact"
	tput sgr0
	cd "$SRC/SDL_image_compact"

	make clean
	make $makearg
	# install -v -p -D -t "$LIBROOT" "$PREFIX/lib/libSDL2_image-2.0.so.0"
	install -v -p -D -t "$LIBROOT" libSDL2_image-2.0.so.0
}

task_mojoshader() {
	tput setaf 2 && tput bold
	echo "==> Building MojoShader"
	tput sgr0
	cd "$SRC/MojoShader"

	rm -rf build
	mkdir -p build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX" -DBUILD_SHARED=ON -DPROFILE_D3D=OFF -DPROFILE_BYTECODE=OFF -DPROFILE_ARB1=OFF -DPROFILE_ARB1_NV=OFF -DPROFILE_METAL=OFF -DCOMPILER_SUPPORT=OFF -DFLIP_VIEWPORT=ON -DDEPTH_CLIPPING=ON -DXNA4_VERTEXTEXTURE=ON -DCMAKE_BUILD_TYPE=Release
	make $makearg
	install -v -p -D -t "$LIBROOT" libmojoshader.so
}

task_faudio() {
	tput setaf 2 && tput bold
	echo "==> Building FAudio"
	tput sgr0
	cd "$SRC/FAudio"

	rm -rf build
	mkdir -p build
	cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_SKIP_BUILD_RPATH=TRUE
	make $makearg
	install -v -p -D -t "$LIBROOT" libFAudio.so.0
}

task_theorafile() {
	tput setaf 2 && tput bold
	echo "==> Building Theorafile"
	tput sgr0
	cd "$SRC/Theorafile"

	make
	install -v -p -D -t "$LIBROOT" libtheorafile.so
}

task_mono() {
	tput setaf 2 && tput bold
	echo "==> Building Mono"
	tput sgr0
	cd "$SRC/Mono"

	./configure --prefix="$PREFIX" --with-mcs-docs=no
	make $makearg
	make install
}

task_monokickstart() {
	tput setaf 2 && tput bold
	echo "==> Building MonoKickstart"
	tput sgr0
	cd "$SRC/MonoKickstart"

	cp -v "$PREFIX/lib/libmonosgen-2.0.a" .

	rm -rf build
	mkdir -p build
	cd build
	CFLAGS=-I$SRC/Mono cmake .. -DCMAKE_BUILD_TYPE=Release
	make $makearg
	install -v -p -D -t "$PRECOMPILED" kick.bin.*
	install -v -p -D -t "$PRECOMPILED" "../precompiled/Kick"

	install -v -p -D -m644 "$PREFIX/etc/mono/4.5/machine.config" "$PRECOMPILED/monomachineconfig"
	install -v -p -D -m644 "$PREFIX/etc/mono/config" "$PRECOMPILED/monoconfig"
	install -v -p -D -t "$PRECOMPILED" \
		"$PREFIX/lib/mono/4.5/Mono.Posix.dll" \
		"$PREFIX/lib/mono/4.5/Mono.Security.dll" \
		"$PREFIX/lib/mono/4.5/System.Configuration.dll" \
		"$PREFIX/lib/mono/4.5/System.Core.dll" \
		"$PREFIX/lib/mono/4.5/System.Data.dll" \
		"$PREFIX/lib/mono/4.5/System.Drawing.dll" \
		"$PREFIX/lib/mono/4.5/System.Numerics.dll" \
		"$PREFIX/lib/mono/4.5/System.Runtime.Serialization.dll" \
		"$PREFIX/lib/mono/4.5/System.Security.dll" \
		"$PREFIX/lib/mono/4.5/System.Xml.Linq.dll" \
		"$PREFIX/lib/mono/4.5/System.Xml.dll" \
		"$PREFIX/lib/mono/4.5/System.dll" \
		"$PREFIX/lib/mono/4.5/mscorlib.dll"
}

task_fna() {
	tput setaf 2 && tput bold
	echo "==> Building FNA"
	tput sgr0
	cd "$SRC/FNA"

	make release

	install -v -p -D -t "$PRECOMPILED" bin/Release/FNA.dll bin/Release/FNA.dll.config
}

# START OF BUILD PROCESS

if [ "$1" == "all" ]; then
	tput setaf 2 && tput bold
	echo "==> Building everything"
	tput sgr0

	task_clean_prefix
	echo

	task_sdl
	echo

	task_sdl_image_compact
	echo

	task_faudio
	echo

	task_mojoshader
	echo

	task_theorafile
	echo

	task_mono
	echo

	task_monokickstart

elif [ ! -z "$1" ]; then
	if [ "$(type -t "task_$1")" = "function" ]; then
		"task_$1"
	else
		tput setaf 1 && tput bold
		echo "==> Error: Task '$1' does not exist"
		tput sgr0
	fi
else
	echo "Usage: ./tasks.sh <task|all>"
fi
