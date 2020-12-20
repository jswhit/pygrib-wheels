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

function build_wheel {
    source multibuild/library_builders.sh
    build_libs
    build_pip_wheel $@
    }

function build_libs {
    build_libpng
    build_openjpep
    build_libaec
#   if [ -z "$IS_OSX" ] && [ $MB_ML_VER -eq 1 ]; then
#       export CFLAGS="-std=gnu99 -Wl,-strip-all"
#    fi
    build_eccodes
}

function build_eccodes {
    if [ -e eccodes-stamp ]; then return; fi
    build_libpng
    build_openjpep
    build_libaec
    fetch_unpack https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz?api=v2
    mkdir build
    cd build
    cmake -DENABLE_JPG_LIBOPENJPEG=ON -DENABLE_PNG=ON -DENABLE_AEC=ON -DENABLE_FORTRAN=OFF-DENABLE_NETCDF=OFF ../eccodes-${ECCODES_VERSION}-Source
    make -j2
    make install
    cd ..
    touch eccodes-stamp
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    cp ../pygrib/test.py
    python test.py
}
