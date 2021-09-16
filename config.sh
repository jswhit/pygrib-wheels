# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Compile libs for macOS 10.9 or later
export MACOSX_DEPLOYMENT_TARGET="10.9"
export ECCODES_VERSION="2.23.0"
export OPENJPEG_VERSION="2.3.1"
export PYGRIB_WHEEL=true

function build_libs {
    build_libpng
    build_openjpeg
    build_libaec
    build_eccodes
}

function pre_build {
    echo "in pre-build $PWD"
    export PYGRIB_DIR=$PWD/pygrib
    pip install cmake>=3.12
    cmake_exec=`which cmake`
    ln -fs ${cmake_exec} /usr/local/bin/cmake
    build_libs
}

function build_eccodes {
    if [ -e eccodes-stamp ]; then return; fi
    build_libpng
    build_openjpeg
    build_libaec
    fetch_unpack https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz
    #/bin/cp -r eccodes-${ECCODES_VERSION}-Source/definitions $PYGRIB_DIR/eccodes
    #/bin/mv $PYGRIB_DIR/eccodes/template.3.32769.def $PYGRIB_DIR/eccodes/definitions/grib2
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
    cd ..
    python utils/grib_list sampledata/rap.wrfnat.grib2 -s
}
