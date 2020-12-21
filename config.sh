# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    :
}

# Compile libs for macOS 10.9 or later
export MACOSX_DEPLOYMENT_TARGET="10.9"
export ECCODES_VERSION="2.19.1"
export OPENJPEG_VERSION="2.3.1"

function build_wheel {
    source multibuild/library_builders.sh
    build_libs
    build_pip_wheel $@
    }

function build_libs {
    build_libpng
    build_openjpeg
    build_libaec
#   if [ -z "$IS_OSX" ] && [ $MB_ML_VER -eq 1 ]; then
#       export CFLAGS="-std=gnu99 -Wl,-strip-all"
#    fi
    build_eccodes
}

function build_eccodes {
    if [ -e eccodes-stamp ]; then return; fi
    build_libpng
    build_openjpeg
    build_libaec
    fetch_unpack https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz
    mkdir build
    cd build
    cmake -DENABLE_FORTRAN=OFF -DENABLE_NETCDF=OFF -DENABLE_TESTS=OFF -DENABLE_JPG_LIBJASPER=OFF -DENABLE_JPG_LIBOPENJPEG=ON -DENABLE_PNG=ON -DENABLE_AEC=ON ../eccodes-${ECCODES_VERSION}-Source
    make -j2
    make install
    cd ..
    if [ -n "$IS_OSX" ]; then
        # Fix eccodes library id bug
        for lib in $(ls ${BUILD_PREFIX}/lib/libeccodes*.dylib); do
            install_name_tool -id $lib $lib
        done
    fi
    touch eccodes-stamp
}

function run_tests {
    cd ../pygrib/test
    python test.py
    python test_latlons.py
}
