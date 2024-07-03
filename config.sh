# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Compile libs for macOS 10.11 or later
export MACOSX_DEPLOYMENT_TARGET="10.11"
export ECCODES_VERSION="2.34.1"
export OPENJPEG_VERSION="2.4.0"
export LIBAEC_VERSION="1.0.6"
export PNG_VERSION="1.6.37"
export ZLIB_VERSION="1.2.11"
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

function build_libaec {
    if [ -e libaec-stamp ]; then return; fi
    local root_name=v${LIBAEC_VERSION}
    local tar_name=libaec-${root_name}.tar.gz
    fetch_unpack https://gitlab.dkrz.de/k202009/libaec/-/archive/${root_name}/${tar_name}
    #fetch_unpack https://gitlab.dkrz.de/k202009/libaec/uploads/45b10e42123edd26ab7b3ad92bcf7be2/libaec-1.0.6.tar.gz
    if [ -n "$IS_MACOS" ]; then
        brew install autoconf automake libtool
    fi
    (cd libaec-${root_name} \
        && autoreconf -i \
        && ./configure --prefix=$BUILD_PREFIX \
        && make \
        && make install)
    touch libaec-stamp
}


function build_eccodes {
    if [ -e eccodes-stamp ]; then return; fi
    build_libpng
    build_openjpeg
    build_libaec
    fetch_unpack https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz
    /bin/cp -r eccodes-${ECCODES_VERSION}-Source/definitions $PYGRIB_DIR/src/pygrib/share/eccodes
    /bin/mv $PYGRIB_DIR/src/pygrib/share/eccodes/template.3.32769.def $PYGRIB_DIR/src/pygrib/share/eccodes/definitions/grib2
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX -DENABLE_FORTRAN=OFF -DENABLE_NETCDF=OFF -DENABLE_TESTS=OFF -DENABLE_JPG_LIBJASPER=OFF -DENABLE_JPG_LIBOPENJPEG=ON -DENABLE_PNG=ON -DENABLE_AEC=ON ../eccodes-${ECCODES_VERSION}-Source
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
    pytest -vv test_latlons.py test.py
    cd ..
    python utils/grib_list sampledata/rap.wrfnat.grib2 -s
}
