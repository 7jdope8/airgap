#!/bin/bash
###############################################################################
# Script to build and install libbitcoin-explorer.
#
# This script is a fork of the official libbitcoin-explorer build script
# modified to hardcode hashes for deterministic builds
#
# Script options:
# --with-icu               Compile with International Components for Unicode.
#                            Since the addition of BIP-39 and later BIP-38
#                            support, libbitcoin conditionally incorporates ICU
#                             to provide BIP-38 and BIP-39 passphrase
#                            normalization features. Currently
#                            libbitcoin-explorer is the only other library that
#                            accesses this feature, so if you do not intend to
#                            use passphrase normalization this dependency can
#                            be avoided.
# --with-png               Compile with QR Code PNG Output Support
#                            Since the addition of png support, libbitcoin
#                            conditionally incorporates libpng (which in turn
#                            requires zlib). Currently libbitcoin-explorer is
#                            the only other library that accesses this feature,
#                            so if you do not intend to use png this dependency
#                            can be avoided.
# --with-qrencode          Compile with QR Code Support
#                            Since the addition of qrcode support, libbitcoin
#                            conditionally incorporates qrencode. Currently
#                            libbitcoin-explorer is the only other library that
#                            accesses this feature, so if you do not intend to
#                            use qrcode this dependency can be avoided.
# --build-icu              Builds ICU libraries.
# --build-zlib             Builds ZLib libraries.
# --build-png              Builds PNG libraries.
# --build-qrencode         Builds QREncode libraries.
# --build-boost            Builds Boost libraries.
# --build-zmq              Builds ZeroMQ libraries.
# --build-dir=<path>       Location of downloaded and intermediate files.
# --prefix=<absolute-path> Library install location (defaults to /usr/local).
# --disable-shared         Disables shared library builds.
# --disable-static         Disables static library builds.
# --help                   Display usage, overriding script execution.

# Define constants.
#==============================================================================
# The default build directory.
#------------------------------------------------------------------------------
BUILD_DIR="build-libbitcoin-explorer"

# ICU archive.
#------------------------------------------------------------------------------
ICU_URL="http://download.icu-project.org/files/icu4c/55.1/icu4c-55_1-src.tgz"
ICU_ARCHIVE="icu4c-55_1-src.tgz"
ICU_HASH="e16b22cbefdd354bec114541f7849a12f8fc2015320ca5282ee4fd787571457b"

# ZLib archive.
#------------------------------------------------------------------------------
ZLIB_URL="https://github.com/madler/zlib/archive/v1.2.9.tar.gz"
ZLIB_ARCHIVE="v1.2.9.tar.gz"
ZLIB_HASH="c1e41e777e007e908ee72ee46a4be1d48b41b55af3440313f36263c08b826c4d"

# PNG archive.
#------------------------------------------------------------------------------
PNG_URL="http://downloads.sourceforge.net/project/libpng/libpng16/older-releases/1.6.29/libpng-1.6.29.tar.xz"
PNG_ARCHIVE="libpng-1.6.29.tar.xz"
PNG_HASH="4245b684e8fe829ebb76186327bb37ce5a639938b219882b53d64bd3cfc5f239"

# QREncode archive.
#------------------------------------------------------------------------------
QRENCODE_URL="http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.bz2"
QRENCODE_ARCHIVE="qrencode-3.4.4.tar.bz2"
QRENCODE_HASH="efe5188b1ddbcbf98763b819b146be6a90481aac30cfc8d858ab78a19cde1fa5"

# ZMQ archive.
#------------------------------------------------------------------------------
ZMQ_URL="https://github.com/zeromq/libzmq/releases/download/v4.2.5/zeromq-4.2.5.tar.gz"
ZMQ_ARCHIVE="zeromq-4.2.5.tar.gz"
ZMQ_HASH="cc9090ba35713d59bb2f7d7965f877036c49c5558ea0c290b0dcc6f2a17e489f"

# Boost archive.
#------------------------------------------------------------------------------
BOOST_URL="http://downloads.sourceforge.net/project/boost/boost/1.62.0/boost_1_62_0.tar.bz2"
BOOST_ARCHIVE="boost_1_62_0.tar.bz2"
BOOST_HASH="36c96b0f6155c98404091d8ceb48319a28279ca0333fba1ad8611eb90afb2ca0"


# Define utility functions.
#==============================================================================
configure_links()
{
    # Configure dynamic linker run-time bindings when installing to system.
    if [[ ($OS == Linux) && ($PREFIX == "/usr/local") ]]; then
        ldconfig
    fi
}

configure_options()
{
    display_message "configure options:"
    for OPTION in "$@"; do
        if [[ $OPTION ]]; then
            display_message $OPTION
        fi
    done

    ./configure "$@"
}

create_directory()
{
    local DIRECTORY="$1"

    rm -rf "$DIRECTORY"
    mkdir "$DIRECTORY"
}

display_heading_message()
{
    echo
    echo "********************** $@ **********************"
    echo
}

display_message()
{
    echo "$@"
}

display_error()
{
    >&2 echo "$@"
}

initialize_git()
{
    display_heading_message "Initialize git"

    # Initialize git repository at the root of the current directory.
    git init
    git config user.name anonymous
}

# make_current_directory jobs [configure_options]
make_current_directory()
{
    local JOBS=$1
    shift 1

    ./autogen.sh
    configure_options "$@"
    make_jobs $JOBS
    make install
    configure_links
}

# make_jobs jobs [make_options]
make_jobs()
{
    local JOBS=$1
    shift 1

    # Avoid setting -j1 (causes problems on Travis).
    if [[ $JOBS > $SEQUENTIAL ]]; then
        make -j$JOBS "$@"
    else
        make "$@"
    fi
}

# make_tests jobs
make_tests()
{
    local JOBS=$1

    # Disable exit on error.
    set +e

    # Build and run unit tests relative to the primary directory.
    # VERBOSE=1 ensures test runner output sent to console (gcc).
    make_jobs $JOBS check "VERBOSE=1"
    local RESULT=$?

    # Test runners emit to the test.log file.
    if [[ -e "test.log" ]]; then
        cat "test.log"
    fi

    if [[ $RESULT -ne 0 ]]; then
        exit $RESULT
    fi

    # Reenable exit on error.
    set -e
}

pop_directory()
{
    popd >/dev/null
}

push_directory()
{
    local DIRECTORY="$1"

    pushd "$DIRECTORY" >/dev/null
}

display_help()
{
    display_message "Usage: ./install.sh [OPTION]..."
    display_message "Manage the installation of libbitcoin-explorer."
    display_message "Script options:"
    display_message "  --with-icu               Compile with International Components for Unicode."
    display_message "                             Since the addition of BIP-39 and later BIP-38 "
    display_message "                             support, libbitcoin conditionally incorporates ICU "
    display_message "                              to provide BIP-38 and BIP-39 passphrase "
    display_message "                             normalization features. Currently "
    display_message "                             libbitcoin-explorer is the only other library that "
    display_message "                             accesses this feature, so if you do not intend to "
    display_message "                             use passphrase normalization this dependency can "
    display_message "                             be avoided."
    display_message "  --with-png               Compile with QR Code PNG Output Support"
    display_message "                             Since the addition of png support, libbitcoin "
    display_message "                             conditionally incorporates libpng (which in turn "
    display_message "                             requires zlib). Currently libbitcoin-explorer is "
    display_message "                             the only other library that accesses this feature, "
    display_message "                             so if you do not intend to use png this dependency "
    display_message "                             can be avoided."
    display_message "  --with-qrencode          Compile with QR Code Support"
    display_message "                             Since the addition of qrcode support, libbitcoin "
    display_message "                             conditionally incorporates qrencode. Currently "
    display_message "                             libbitcoin-explorer is the only other library that "
    display_message "                             accesses this feature, so if you do not intend to "
    display_message "                             use qrcode this dependency can be avoided."
    display_message "  --build-icu              Builds ICU libraries."
    display_message "  --build-zlib             Builds ZLib libraries."
    display_message "  --build-png              Builds PNG libraries."
    display_message "  --build-qrencode         Builds QREncode libraries."
    display_message "  --build-boost            Builds Boost libraries."
    display_message "  --build-zmq              Build ZeroMQ libraries."
    display_message "  --build-dir=<path>       Location of downloaded and intermediate files."
    display_message "  --prefix=<absolute-path> Library install location (defaults to /usr/local)."
    display_message "  --disable-shared         Disables shared library builds."
    display_message "  --disable-static         Disables static library builds."
    display_message "  --help                   Display usage, overriding script execution."
    display_message ""
    display_message "All unrecognized options provided shall be passed as configuration options for "
    display_message "all dependencies."
}

# Initialize the build environment.
#==============================================================================
# Exit this script on the first build error.
#------------------------------------------------------------------------------
set -e

# Parse command line options that are handled by this script.
#------------------------------------------------------------------------------
for OPTION in "$@"; do
    case $OPTION in
        # Standard script options.
        (--help)                DISPLAY_HELP="yes";;

        # Standard build options.
        (--prefix=*)            PREFIX="${OPTION#*=}";;
        (--disable-shared)      DISABLE_SHARED="yes";;
        (--disable-static)      DISABLE_STATIC="yes";;

        # Common project options.
        (--with-icu)            WITH_ICU="yes";;
        (--with-png)            WITH_PNG="yes";;
        (--with-qrencode)       WITH_QRENCODE="yes";;

        # Custom build options (in the form of --build-<option>).
        (--build-icu)           BUILD_ICU="yes";;
        (--build-zlib)          BUILD_ZLIB="yes";;
        (--build-png)           BUILD_PNG="yes";;
        (--build-qrencode)      BUILD_QRENCODE="yes";;
        (--build-zmq)           BUILD_ZMQ="yes";;
        (--build-boost)         BUILD_BOOST="yes";;

        # Unique script options.
        (--build-dir=*)    BUILD_DIR="${OPTION#*=}";;
    esac
done

# Configure build parallelism.
#------------------------------------------------------------------------------
SEQUENTIAL=1
OS=`uname -s`
if [[ $PARALLEL ]]; then
    display_message "Using shell-defined PARALLEL value."
elif [[ $OS == Linux ]]; then
    PARALLEL=`nproc`
elif [[ ($OS == Darwin) || ($OS == OpenBSD) ]]; then
    PARALLEL=`sysctl -n hw.ncpu`
else
    display_error "Unsupported system: $OS"
    display_error "  Explicit shell-definition of PARALLEL will avoid system detection."
    display_error ""
    display_help
    exit 1
fi

# Define operating system specific settings.
#------------------------------------------------------------------------------
if [[ $OS == Darwin ]]; then
    export CC="clang"
    export CXX="clang++"
    STDLIB="c++"
elif [[ $OS == OpenBSD ]]; then
    make() { gmake "$@"; }
    export CC="egcc"
    export CXX="eg++"
    STDLIB="estdc++"
else # Linux
    STDLIB="stdc++"
fi

# Link to appropriate standard library in non-default scnearios.
#------------------------------------------------------------------------------
if [[ ($OS == Linux && $CC == "clang") || ($OS == OpenBSD) ]]; then
    export LDLIBS="-l$STDLIB $LDLIBS"
    export CXXFLAGS="-stdlib=lib$STDLIB $CXXFLAGS"
fi

# Normalize of static and shared options.
#------------------------------------------------------------------------------
if [[ $DISABLE_SHARED ]]; then
    CONFIGURE_OPTIONS=("$@" "--enable-static")
elif [[ $DISABLE_STATIC ]]; then
    CONFIGURE_OPTIONS=("$@" "--enable-shared")
else
    CONFIGURE_OPTIONS=("$@" "--enable-shared")
    CONFIGURE_OPTIONS=("$@" "--enable-static")
fi

# Purge custom build options so they don't break configure.
#------------------------------------------------------------------------------
CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]/--build-*/}")

# Always set a prefix (required on OSX and for lib detection).
#------------------------------------------------------------------------------
if [[ !($PREFIX) ]]; then
    PREFIX="/usr/local"
    CONFIGURE_OPTIONS=( "${CONFIGURE_OPTIONS[@]}" "--prefix=$PREFIX")
else
    # Incorporate the custom libdir into each object, for runtime resolution.
    export LD_RUN_PATH="$PREFIX/lib"
fi

# Incorporate the prefix.
#------------------------------------------------------------------------------
# Set the prefix-based package config directory.
PREFIX_PKG_CONFIG_DIR="$PREFIX/lib/pkgconfig"

# Prioritize prefix package config in PKG_CONFIG_PATH search path.
export PKG_CONFIG_PATH="$PREFIX_PKG_CONFIG_DIR:$PKG_CONFIG_PATH"

# Set a package config save path that can be passed via our builds.
with_pkgconfigdir="--with-pkgconfigdir=$PREFIX_PKG_CONFIG_DIR"

if [[ $BUILD_BOOST ]]; then
    # Boost has no pkg-config, m4 searches in the following order:
    # --with-boost=<path>, /usr, /usr/local, /opt, /opt/local, $BOOST_ROOT.
    # We use --with-boost to prioritize the --prefix path when we build it.
    # Otherwise standard paths suffice for Linux, Homebrew and MacPorts.
    # ax_boost_base.m4 appends /include and adds to BOOST_CPPFLAGS
    # ax_boost_base.m4 searches for /lib /lib64 and adds to BOOST_LDFLAGS
    with_boost="--with-boost=$PREFIX"
fi

display_configuration()
{
    display_message "libbitcoin-explorer installer configuration."
    display_message "--------------------------------------------------------------------"
    display_message "OS                    : $OS"
    display_message "PARALLEL              : $PARALLEL"
    display_message "CC                    : $CC"
    display_message "CXX                   : $CXX"
    display_message "CPPFLAGS              : $CPPFLAGS"
    display_message "CFLAGS                : $CFLAGS"
    display_message "CXXFLAGS              : $CXXFLAGS"
    display_message "LDFLAGS               : $LDFLAGS"
    display_message "LDLIBS                : $LDLIBS"
    display_message "WITH_ICU              : $WITH_ICU"
    display_message "WITH_PNG              : $WITH_PNG"
    display_message "WITH_QRENCODE         : $WITH_QRENCODE"
    display_message "BUILD_ICU             : $BUILD_ICU"
    display_message "BUILD_ZLIB            : $BUILD_ZLIB"
    display_message "BUILD_PNG             : $BUILD_PNG"
    display_message "BUILD_QRENCODE        : $BUILD_QRENCODE"
    display_message "BUILD_ZMQ             : $BUILD_ZMQ"
    display_message "BUILD_BOOST           : $BUILD_BOOST"
    display_message "BUILD_DIR             : $BUILD_DIR"
    display_message "PREFIX                : $PREFIX"
    display_message "DISABLE_SHARED        : $DISABLE_SHARED"
    display_message "DISABLE_STATIC        : $DISABLE_STATIC"
    display_message "with_boost            : ${with_boost}"
    display_message "with_pkgconfigdir     : ${with_pkgconfigdir}"
    display_message "--------------------------------------------------------------------"
}


# Define build options.
#==============================================================================
# Define icu options.
#------------------------------------------------------------------------------
ICU_OPTIONS=(
"--enable-draft" \
"--enable-tools" \
"--disable-extras" \
"--disable-icuio" \
"--disable-layout" \
"--disable-layoutex" \
"--disable-tests" \
"--disable-samples")

# Define boost options.
#------------------------------------------------------------------------------
BOOST_OPTIONS=(
"--with-atomic" \
"--with-chrono" \
"--with-date_time" \
"--with-filesystem" \
"--with-iostreams" \
"--with-locale" \
"--with-log" \
"--with-program_options" \
"--with-regex" \
"--with-system" \
"--with-thread" \
"--with-test")

# Define secp256k1 options.
#------------------------------------------------------------------------------
SECP256K1_OPTIONS=(
"--disable-tests" \
"--enable-module-recovery")

# Define bitcoin options.
#------------------------------------------------------------------------------
BITCOIN_OPTIONS=(
"--without-tests" \
"--without-examples" \
"${with_boost}" \
"${with_pkgconfigdir}")

# Define bitcoin-protocol options.
#------------------------------------------------------------------------------
BITCOIN_PROTOCOL_OPTIONS=(
"--without-tests" \
"--without-examples" \
"${with_boost}" \
"${with_pkgconfigdir}")

# Define bitcoin-client options.
#------------------------------------------------------------------------------
BITCOIN_CLIENT_OPTIONS=(
"--without-tests" \
"--without-examples" \
"${with_boost}" \
"${with_pkgconfigdir}")

# Define bitcoin-network options.
#------------------------------------------------------------------------------
BITCOIN_NETWORK_OPTIONS=(
"--without-tests" \
"${with_boost}" \
"${with_pkgconfigdir}")

# Define bitcoin-explorer options.
#------------------------------------------------------------------------------
BITCOIN_EXPLORER_OPTIONS=(
"${with_boost}" \
"${with_pkgconfigdir}")


# Define build functions.
#==============================================================================
# Because PKG_CONFIG_PATH doesn't get updated by Homebrew or MacPorts.
initialize_icu_packages()
{
    if [[ ($OS == Darwin) ]]; then
        # Update PKG_CONFIG_PATH for ICU package installations on OSX.
        # OSX provides libicucore.dylib with no pkgconfig and doesn't support
        # renaming or important features, so we can't use that.
        local HOMEBREW_ICU_PKG_CONFIG="/usr/local/opt/icu4c/lib/pkgconfig"
        local MACPORTS_ICU_PKG_CONFIG="/opt/local/lib/pkgconfig"

        if [[ -d "$HOMEBREW_ICU_PKG_CONFIG" ]]; then
            export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$HOMEBREW_ICU_PKG_CONFIG"
        elif [[ -d "$MACPORTS_ICU_PKG_CONFIG" ]]; then
            export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$MACPORTS_ICU_PKG_CONFIG"
        fi
    fi
}

# Because ZLIB doesn't actually parse its --disable-shared option.
# Because ZLIB doesn't follow GNU recommentation for unknown arguments.
patch_zlib_configuration()
{
    sed -i.tmp "s/leave 1/shift/" configure
    sed -i.tmp "s/--static/--static | --disable-shared/" configure
    sed -i.tmp "/unknown option/d" configure
    sed -i.tmp "/help for help/d" configure

    # display_message "Hack: ZLIB configuration options modified."
}

# Because ZLIB can't build shared only.
clean_zlib_build()
{
    if [[ $DISABLE_STATIC ]]; then
        rm --force "$PREFIX/lib/libz.a"
    fi
}

# Standard build from tarball.
build_from_tarball()
{
    local URL=$1
    local ARCHIVE=$2
    local HASH=$3
    local COMPRESSION=$4
    local PUSH_DIR=$5
    local JOBS=$6
    local BUILD=$7
    local OPTIONS=$8
    shift 8

    # For some platforms we need to set ICU pkg-config path.
    if [[ !($BUILD) ]]; then
        if [[ $ARCHIVE == $ICU_ARCHIVE ]]; then
            initialize_icu_packages
        fi
        return
    fi

    # Because libpng doesn't actually use pkg-config to locate zlib.
    # Because ICU tools don't know how to locate internal dependencies.
    if [[ ($ARCHIVE == $ICU_ARCHIVE) || ($ARCHIVE == $PNG_ARCHIVE) ]]; then
        local SAVE_LDFLAGS=$LDFLAGS
        export LDFLAGS="-L$PREFIX/lib $LDFLAGS"
    fi

    # Because libpng doesn't actually use pkg-config to locate zlib.h.
    if [[ ($ARCHIVE == $PNG_ARCHIVE) ]]; then
        local SAVE_CPPFLAGS=$CPPFLAGS
        export CPPFLAGS="-I$PREFIX/include $CPPFLAGS"
    fi

    display_heading_message "Download $ARCHIVE"

    # Use the suffixed archive name as the extraction directory.
    local EXTRACT="build-$ARCHIVE"
    push_directory "$BUILD_DIR"
    create_directory "$EXTRACT"
    push_directory "$EXTRACT"

    # Extract the source locally.
    wget --output-document $ARCHIVE $URL
    [ "$HASH" == "$(sha256sum "$ARCHIVE" | cut -d' ' -f1)" ] || {
    	printf "hash check failed for "$ARCHIVE""; exit 1;
    }
    tar --extract --file $ARCHIVE --$COMPRESSION --strip-components=1
    push_directory "$PUSH_DIR"

    # Enable static only zlib build.
    if [[ $ARCHIVE == $ZLIB_ARCHIVE ]]; then
        patch_zlib_configuration
    fi

    # Join generated and command line options.
    local CONFIGURATION=("${OPTIONS[@]}" "$@")

    configure_options "${CONFIGURATION[@]}"
    make_jobs $JOBS --silent
    make install
    configure_links

    # Enable shared only zlib build.
    if [[ $ARCHIVE == $ZLIB_ARCHIVE ]]; then
        clean_zlib_build
    fi

    pop_directory
    pop_directory

    # Restore flags to prevent side effects.
    export LDFLAGS=$SAVE_LDFLAGS
    export CPPFLAGS=$SAVE_LCPPFLAGS

    pop_directory
}

# Because boost ICU detection assumes in incorrect ICU path.
circumvent_boost_icu_detection()
{
    # Boost expects a directory structure for ICU which is incorrect.
    # Boost ICU discovery fails when using prefix, can't fix with -sICU_LINK,
    # so we rewrite the two 'has_icu_test.cpp' files to always return success.

    local SUCCESS="int main() { return 0; }"
    local REGEX_TEST="libs/regex/build/has_icu_test.cpp"
    local LOCALE_TEST="libs/locale/build/has_icu_test.cpp"

    echo $SUCCESS > $REGEX_TEST
    echo $SUCCESS > $LOCALE_TEST

    # display_message "Hack: ICU detection modified, will always indicate found."
}

# Because boost doesn't support autoconfig and doesn't like empty settings.
initialize_boost_configuration()
{
    if [[ $DISABLE_STATIC ]]; then
        BOOST_LINK="shared"
    elif [[ $DISABLE_SHARED ]]; then
        BOOST_LINK="static"
    else
        BOOST_LINK="static,shared"
    fi

    if [[ $CC ]]; then
        BOOST_TOOLSET="toolset=$CC"
    fi

    if [[ ($OS == Linux && $CC == "clang") || ($OS == OpenBSD) ]]; then
        STDLIB_FLAG="-stdlib=lib$STDLIB"
        BOOST_CXXFLAGS="cxxflags=$STDLIB_FLAG"
        BOOST_LINKFLAGS="linkflags=$STDLIB_FLAG"
    fi
}

# Because boost doesn't use pkg-config.
initialize_boost_icu_configuration()
{
    BOOST_ICU_ICONV="on"
    BOOST_ICU_POSIX="on"

    if [[ $WITH_ICU ]]; then
        circumvent_boost_icu_detection

        # Restrict other locale options when compiling boost with icu.
        BOOST_ICU_ICONV="off"
        BOOST_ICU_POSIX="off"

        # Extract ICU libs from package config variables and augment with -ldl.
        ICU_LIBS=( `pkg-config icu-i18n --libs` "-ldl" )

        # This is a hack for boost m4 scripts that fail with ICU dependency.
        # See custom edits in ax-boost-locale.m4 and ax_boost_regex.m4.
        export BOOST_ICU_LIBS="${ICU_LIBS[@]}"

        # Extract ICU prefix directory from package config variable.
        ICU_PREFIX=`pkg-config icu-i18n --variable=prefix`
    fi
}

# Because boost doesn't use autoconfig.
build_from_tarball_boost()
{
    local URL=$1
    local ARCHIVE=$2
    local HASH=$3
    local COMPRESSION=$4
    local PUSH_DIR=$5
    local JOBS=$6
    local BUILD=$7
    shift 7

    if [[ !($BUILD) ]]; then
        return
    fi

    display_heading_message "Download $ARCHIVE"

    # Use the suffixed archive name as the extraction directory.
    local EXTRACT="build-$ARCHIVE"
    push_directory "$BUILD_DIR"
    create_directory "$EXTRACT"
    push_directory "$EXTRACT"

    # Extract the source locally.
    wget --output-document $ARCHIVE $URL
    [ "$HASH" == "$(sha256sum "$ARCHIVE" | cut -d' ' -f1)" ] || {
    	printf "hash check failed for "$ARCHIVE""; exit 1;
    }
    tar --extract --file $ARCHIVE --$COMPRESSION --strip-components=1

    initialize_boost_configuration
    initialize_boost_icu_configuration

    display_message "Libbitcoin boost configuration."
    display_message "--------------------------------------------------------------------"
    display_message "variant               : release"
    display_message "threading             : multi"
    display_message "toolset               : $CC"
    display_message "cxxflags              : $STDLIB_FLAG"
    display_message "linkflags             : $STDLIB_FLAG"
    display_message "link                  : $BOOST_LINK"
    display_message "boost.locale.iconv    : $BOOST_ICU_ICONV"
    display_message "boost.locale.posix    : $BOOST_ICU_POSIX"
    display_message "-sNO_BZIP2            : 1"
    display_message "-sICU_PATH            : $ICU_PREFIX"
    display_message "-sICU_LINK            : ${ICU_LIBS[@]}"
    display_message "-sZLIB_LIBPATH        : $PREFIX/lib"
    display_message "-sZLIB_INCLUDE        : $PREFIX/include"
    display_message "-j                    : $JOBS"
    display_message "-d0                   : [supress informational messages]"
    display_message "-q                    : [stop at the first error]"
    display_message "--reconfigure         : [ignore cached configuration]"
    display_message "--prefix              : $PREFIX"
    display_message "BOOST_OPTIONS         : $@"
    display_message "--------------------------------------------------------------------"

    # boost_iostreams
    # The zlib options prevent boost linkage to system libs in the case where
    # we have built zlib in a prefix dir. Disabling zlib in boost is broken in
    # all versions (through 1.60). https://svn.boost.org/trac/boost/ticket/9156
    # The bzip2 auto-detection is not implemented, but disabling it works.

    ./bootstrap.sh \
        "--prefix=$PREFIX" \
        "--with-icu=$ICU_PREFIX"

    ./b2 install \
        "variant=release" \
        "threading=multi" \
        "$BOOST_TOOLSET" \
        "$BOOST_CXXFLAGS" \
        "$BOOST_LINKFLAGS" \
        "link=$BOOST_LINK" \
        "boost.locale.iconv=$BOOST_ICU_ICONV" \
        "boost.locale.posix=$BOOST_ICU_POSIX" \
        "-sNO_BZIP2=1" \
        "-sICU_PATH=$ICU_PREFIX" \
        "-sICU_LINK=${ICU_LIBS[@]}" \
        "-sZLIB_LIBPATH=$PREFIX/lib" \
        "-sZLIB_INCLUDE=$PREFIX/include" \
        "-j $JOBS" \
        "-d0" \
        "-q" \
        "--reconfigure" \
        "--prefix=$PREFIX" \
        "$@"

    pop_directory
    pop_directory
}

# Standard build from github.
build_from_github()
{
    push_directory "$BUILD_DIR"

    local ACCOUNT=$1
    local REPO=$2
    local BRANCH=$3
    local HASH=$4
    local JOBS=$5
    local OPTIONS=$6
    shift 6

    FORK="$ACCOUNT/$REPO"
    display_heading_message "Download $FORK/$BRANCH"

    # Clone the repository locally.
    git clone -b "$BRANCH" --depth 1 --single-branch "https://github.com/$FORK"
    git --git-dir="$REPO/.git" --work-tree="$REPO" checkout "$HASH" || {
    	printf "Unable to verify hash for $REPO"; exit 1;
    }

    # Join generated and command line options.
    local CONFIGURATION=("${OPTIONS[@]}" "$@")

    # Build the local repository clone.
    push_directory "$REPO"
    make_current_directory $JOBS "${CONFIGURATION[@]}"
    pop_directory
    pop_directory
}

# Standard build of current directory.
build_from_local()
{
    local MESSAGE="$1"
    local JOBS=$2
    local OPTIONS=$3
    shift 3

    display_heading_message "$MESSAGE"

    # Join generated and command line options.
    local CONFIGURATION=("${OPTIONS[@]}" "$@")

    # Build the current directory.
    make_current_directory $JOBS "${CONFIGURATION[@]}"
}

# Because Travis alread has downloaded the primary repo.
build_from_travis()
{
    local ACCOUNT=$1
    local REPO=$2
    local BRANCH=$3
    local HASH=$4
    local JOBS=$5
    local OPTIONS=$6
    shift 6

    # The primary build is not downloaded if we are running in Travis.
    if [[ $TRAVIS == true ]]; then
        build_from_local "Local $TRAVIS_REPO_SLUG" $JOBS "${OPTIONS[@]}" "$@"
        make_tests $JOBS
    else
        build_from_github $ACCOUNT $REPO $BRANCH $HASH $JOBS "${OPTIONS[@]}" "$@"
        push_directory "$BUILD_DIR"
        push_directory "$REPO"
        make_tests $JOBS
        pop_directory
        pop_directory
    fi
}


# The master build function.
#==============================================================================
build_all()
{
    build_from_tarball $ICU_URL $ICU_ARCHIVE $ICU_HASH gzip source $PARALLEL "$BUILD_ICU" "${ICU_OPTIONS[@]}" "$@"
    build_from_tarball $ZLIB_URL $ZLIB_ARCHIVE $ZLIB_HASH gzip . $PARALLEL "$BUILD_ZLIB" "${ZLIB_OPTIONS[@]}" "$@"
    build_from_tarball $PNG_URL $PNG_ARCHIVE $PNG_HASH xz . $PARALLEL "$BUILD_PNG" "${PNG_OPTIONS[@]}" "$@"
    build_from_tarball $QRENCODE_URL $QRENCODE_ARCHIVE $QRENCODE_HASH bzip2 . $PARALLEL "$BUILD_QRENCODE" "${QRENCODE_OPTIONS[@]}" "$@"
    build_from_tarball_boost $BOOST_URL $BOOST_ARCHIVE $BOOST_HASH bzip2 . $PARALLEL "$BUILD_BOOST" "${BOOST_OPTIONS[@]}"
    build_from_tarball $ZMQ_URL $ZMQ_ARCHIVE $ZMQ_HASH gzip . $PARALLEL "$BUILD_ZMQ" "${ZMQ_OPTIONS[@]}" "$@"
    build_from_github libbitcoin secp256k1 version5 38ccc51fb6ef11c33ee30fca8d9200e1f19aaee4 $PARALLEL ${SECP256K1_OPTIONS[@]} "$@"
    build_from_github libbitcoin libbitcoin version3 159783c8e56ba2eb7bc441a7a81dfbf21948d4fb $PARALLEL ${BITCOIN_OPTIONS[@]} "$@"
    build_from_github libbitcoin libbitcoin-protocol version3 6d680b7ef58c64ced0f8da7a22924dd21d1cc0e8 $PARALLEL ${BITCOIN_PROTOCOL_OPTIONS[@]} "$@"
    build_from_github libbitcoin libbitcoin-client version3 f801390ba0eb5abb4021a2ecfd638ce876953c55 $PARALLEL ${BITCOIN_CLIENT_OPTIONS[@]} "$@"
    build_from_github libbitcoin libbitcoin-network version3 4267b11ece4383c321d2d85048f5b46e7f9abfe9 $PARALLEL ${BITCOIN_NETWORK_OPTIONS[@]} "$@"
    build_from_travis libbitcoin libbitcoin-explorer version3 161b9c8781d27247c043d8050ec04755b57ae13e $PARALLEL ${BITCOIN_EXPLORER_OPTIONS[@]} "$@"
}


# Build the primary library and all dependencies.
#==============================================================================
if [[ $DISPLAY_HELP ]]; then
    display_help
else
    display_configuration
    create_directory "$BUILD_DIR"
    push_directory "$BUILD_DIR"
    initialize_git
    pop_directory
    time build_all "${CONFIGURE_OPTIONS[@]}"
fi