# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

export ECCODES_VERSION="2.36.0"
export OPENJPEG_VERSION="2.5.2"
export PNG_VERSION="1.6.43"
export ZLIB_VERSION="1.3.1"
export LIBAEC_VERSION="1.1.3"
export PYGRIB_WHEEL=true
export LCMS2_VERSION="2.7"

function build_simple {
    # Example: build_simple libpng $LIBPNG_VERSION \
    #               https://download.sourceforge.net/libpng tar.gz \
    #               --additional --configure --arguments
    local name=$1
    local version=$2
    local url=$3
    local ext=${4:-tar.gz}
    local configure_args=${@:5}
    if [ -e "${name}-stamp" ]; then
        return
    fi
    local name_version="${name}-${version}"
    local archive=${name_version}.${ext}
    fetch_unpack $url/$archive
    (cd $name_version \
        && ./configure --prefix=$BUILD_PREFIX $configure_args \
        && make -j4 \
        && if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi)
    touch "${name}-stamp"
}

function build_jpeg {
    if [ -e jpeg-stamp ]; then return; fi
    fetch_unpack http://ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz
    (cd jpeg-${JPEG_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi)
    touch jpeg-stamp
}

function build_openjpeg {
    if [ -e openjpeg-stamp ]; then return; fi
    build_zlib
    build_libpng
    build_tiff
    build_lcms2
    local cmake=$(get_modern_cmake)
    local archive_prefix="v"
    if [ $(lex_ver $OPENJPEG_VERSION) -lt $(lex_ver 2.1.1) ]; then
        archive_prefix="version."
    fi
    local out_dir=$(fetch_unpack https://github.com/uclouvain/openjpeg/archive/${archive_prefix}${OPENJPEG_VERSION}.tar.gz)
    (cd $out_dir \
        && $cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX . \
        && if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi)
    touch openjpeg-stamp
}

function build_libaec {
    if [ -e libaec-stamp ]; then return; fi
    local root_name=libaec-1.0.6
    local tar_name=${root_name}.tar.gz
    # Note URL will change for each version
    fetch_unpack https://gitlab.dkrz.de/k202009/libaec/uploads/ea0b7d197a950b0c110da8dfdecbb71f/${tar_name}
    (cd $root_name \
        && ./configure --prefix=$BUILD_PREFIX \
        && make \
        && if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi)
    touch libaec-stamp
}

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
    if [ -n "$IS_MACOS" ]; then
        brew install autoconf automake libtool
    fi
    (cd libaec-${root_name} \
        && autoreconf -i \
        && ./configure --prefix=$BUILD_PREFIX \
        && make \
        && if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi)
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
    if [ -n "$IS_MACOS" ]; then /usr/bin/sudo make install; else make install; fi
    cd ..
    if [ -n "$IS_OSX" ]; then
        # Fix eccodes library id bug
        for lib in $(ls ${BUILD_PREFIX}/lib/libeccodes*.dylib); do
            if [ -n "$IS_MACOS" ]; then sudo install_name_tool -id $lib $lib; else install_name_tool -id $lib $lib; fi
        done
    fi
    touch eccodes-stamp
}

function run_tests {
    cd ../pygrib/test
    pip install pytest
    pytest -vv test.py test_latlons.py
    cd ..
    python utils/grib_list sampledata/rap.wrfnat.grib2 -s
}
