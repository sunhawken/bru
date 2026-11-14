#!/usr/bin/env bash
# Build the Brutal Morrowind Linux package inside the CI/brutal/linux.Containerfile image.
#   build-linux.sh [WORK_DIR] [OUTPUT_DIR]
# The package is a folder with the programs (<name>.x86_64 plus a shell wrapper
# <name> that sets LD_LIBRARY_PATH and QT_PLUGIN_PATH), lib/ with the bundled
# libraries and OSG plugins, plugins/ with the Qt plugins, resources/ and the
# local openmw.cfg.
set -euo pipefail
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(realpath -m "${1:-$SRC/build-linux}")"
OUT="$(realpath -m "${2:-$SRC/dist}")"
JOBS="${JOBS:-$(nproc)}"
DEPS=/opt/deps
VERSION="$(sed -n 's/^set(BRUTAL_VERSION_\(MAJOR\|MINOR\|RELEASE\) \([0-9]*\))$/\2/p' "$SRC/CMakeLists.txt" | paste -sd.)"
NAME="BrutalMorrowind-$VERSION-Linux-64Bit"
mkdir -p "$WORK" "$OUT"

# Importer runtime: standalone CPython with numpy and Pillow.
python3 "$SRC/tools/dm-import/package_python.py" "$WORK/python-runtime" --cache "$WORK/cache"

# Resources and the importer are staged afresh, so files removed from the source
# do not linger in a reused build directory.
rm -rf "$WORK/build/resources" "$WORK/build/tools/dm-import/stage" "$WORK/build/dm-import"
# Compiler cache, when the caller provides one (CCACHE_DIR).
launcher=()
[[ -n "${CCACHE_DIR:-}" ]] && launcher=(-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
cmake -S "$SRC" -B "$WORK/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$DEPS" "${launcher[@]}" \
    -DBUILD_OPENMW=ON -DBUILD_LAUNCHER=ON -DBUILD_WIZARD=ON -DBUILD_MWINIIMPORTER=ON -DBUILD_NAVMESHTOOL=ON \
    -DBUILD_OPENCS=OFF -DBUILD_ESSIMPORTER=OFF -DBUILD_BSATOOL=OFF -DBUILD_ESMTOOL=OFF -DBUILD_NIFTEST=OFF \
    -DBUILD_BULLETOBJECTTOOL=OFF -DBUILD_COMPONENTS_TESTS=OFF -DBUILD_OPENMW_TESTS=OFF -DBUILD_DOCS=OFF \
    -DOPENMW_USE_SYSTEM_OSG=ON -DOPENMW_USE_SYSTEM_BULLET=ON -DOPENMW_USE_SYSTEM_MYGUI=ON \
    -DBRUTAL_PYTHON_RUNTIME="$WORK/python-runtime"
cmake --build "$WORK/build" --parallel "$JOBS"

PKG="$WORK/$NAME"
rm -rf "$PKG"
mkdir -p "$PKG/lib/osgPlugins-3.6.5" "$PKG/plugins" "$PKG/desktop files"

# Programs and their wrappers.
QT_PROGRAMS=(brutalmorrowind-launcher brutalmorrowind-wizard)
PROGRAMS=(brutalmorrowind brutalmorrowind-iniimporter brutalmorrowind-navmeshtool "${QT_PROGRAMS[@]}")
wrapper() { # program extra-environment
    cat > "$PKG/$1" <<EOF
#!/bin/sh
# Runs $1.x86_64 with the libraries shipped in ./lib.
SCRIPT="\$0"
while [ -L "\$SCRIPT" ]; do
    LINK=\$(ls -l "\$SCRIPT" | sed 's/^.*-> //')
    case "\$LINK" in
        /*) SCRIPT="\$LINK" ;;
        *) SCRIPT="\$(dirname "\$SCRIPT")/\$LINK" ;;
    esac
done
cd "\$(dirname "\$SCRIPT")" || { echo "Failed to enter \$(dirname "\$SCRIPT")"; exit 1; }
$2
if [ -n "\$DEBUG" ]; then
    command -v gdb >/dev/null 2>&1 || { echo "Could not find gdb"; exit 1; }
    export DEBUGINFOD_URLS=""
    exec gdb --args ./$1.x86_64 "\$@"
fi
exec ./$1.x86_64 "\$@"
EOF
    chmod 755 "$PKG/$1"
}
for program in "${PROGRAMS[@]}"; do
    cp "$WORK/build/$program" "$PKG/$program.x86_64"
    environment='export LD_LIBRARY_PATH="./lib"'
    [[ " ${QT_PROGRAMS[*]} " == *" $program "* ]] && environment+=$'\nexport QT_PLUGIN_PATH="./plugins"'
    wrapper "$program" "$environment"
done
# The importer runs its own Python, which must not see the game's libraries.
cp "$WORK/build/brutalmorrowind-import" "$PKG/brutalmorrowind-import.x86_64"
wrapper brutalmorrowind-import 'unset LD_LIBRARY_PATH QT_PLUGIN_PATH'
cp -r "$WORK/build/dm-import" "$PKG/dm-import"
rm -f "$PKG/dm-import/python/.copied"

cp "$WORK/build/openmw.cfg" "$WORK/build/defaults.bin" "$WORK/build/gamecontrollerdb.txt" "$PKG/"
cp -r "$WORK/build/resources" "$PKG/"
cp "$SRC/files/launcher/images/openmw.png" "$PKG/brutalmorrowind.png"
cp "$WORK/build/brutalmorrowind.desktop" "$PKG/desktop files/"
cp "$SRC/README.md" "$SRC/LICENSE" "$SRC/CHANGELOG.md" "$SRC/AUTHORS.md" "$PKG/"
[[ -f "$SRC/CREDITS.md" ]] && cp "$SRC/CREDITS.md" "$PKG/"
cp "$SRC/CI/brutal/README.packagecontents.txt" "$PKG/"

# OSG plugins the engine loads.
for plugin in bmp dae dds freetype glsl jpeg osg png serializers_osg tga; do
    cp "$DEPS/lib/osgPlugins-3.6.5/osgdb_$plugin.so" "$PKG/lib/osgPlugins-3.6.5/"
done

# Qt plugins, whole folders.
QT_PLUGINS=/usr/lib/x86_64-linux-gnu/qt6/plugins
for folder in egldeviceintegrations generic iconengines imageformats networkinformation platforminputcontexts \
    platforms platformthemes printsupport sqldrivers tls wayland-decoration-client \
    wayland-graphics-integration-client wayland-graphics-integration-server wayland-shell-integration \
    xcbglintegrations; do
    [[ -d "$QT_PLUGINS/$folder" ]] && cp -r "$QT_PLUGINS/$folder" "$PKG/plugins/"
done

# Libraries: everything the programs, the OSG plugins and the Qt plugins for
# windows, input, images and the Wayland client load, except what is left to
# the system: the C/C++ runtime, zlib, graphics drivers,
# X11/xcb, Wayland, xkbcommon, desktop services, and the GTK, CUPS, libinput and
# Kerberos stacks that only optional plugins use (such a plugin is simply not
# loaded on a system without them). The VNC platform plugin is shipped but not
# walked: only it needs QtNetwork, and through it libproxy and curl.
SYSTEM='^(ld-linux.*|lib(c|m|dl|pthread|rt|util|resolv|stdc\+\+|gcc_s|z)\.so.*|lib(GL|GLX|OpenGL|EGL|GLdispatch|GLESv2|gbm|drm)\.so.*|libX[^/]*\.so.*|libxcb(-(glx|icccm|image|keysyms|randr|render|render-util|shape|shm|sync|util|xfixes|xkb|xinerama|dri2|dri3|present))?\.so.*|libSM\.so.*|libICE\.so.*|libwayland-[^/]*\.so.*|libxkbcommon[^/]*\.so.*|libdbus-1\.so.*|libudev\.so.*|libsystemd\.so.*|libinput\.so.*|libmtdev\.so.*|lib(gtk-3|gdk-3|gdk_pixbuf-2\.0|pango[^/]*|cairo[^/]*|atk[^/]*|atspi|epoxy|cups|gssapi_krb5|krb5|k5crypto|krb5support|com_err)\.so.*)$'
mapfile -t elves < <(find "$PKG" -maxdepth 1 -type f -name '*.x86_64'
    find "$PKG/lib/osgPlugins-3.6.5" -type f -name '*.so'
    find "$PKG/plugins/platforms" "$PKG/plugins/platforminputcontexts" "$PKG/plugins/imageformats" \
        "$PKG/plugins/iconengines" "$PKG/plugins/xcbglintegrations" "$PKG/plugins/wayland-decoration-client" \
        "$PKG/plugins/wayland-graphics-integration-client" -type f -name '*.so' ! -name 'libqvnc.so'
    find "$PKG/plugins/wayland-shell-integration" -type f \( -name 'libxdg-shell.so' -o -name 'libwl-shell-plugin.so' \
        -o -name 'libivi-shell.so' \))
LD_LIBRARY_PATH="$PKG/lib:$DEPS/lib" python3 "$SRC/CI/brutal/bundle_libs.py" "$PKG/lib" "$SYSTEM" "${elves[@]}"

tar -C "$WORK" -czf "$OUT/$NAME.tar.gz" "$NAME"
echo "Package: $OUT/$NAME.tar.gz"
