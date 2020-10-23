#!/bin/bash
# Compilation of PostgreSQL, GEOS, Proj4, GDAL and PostGIS 3
set -exu

exec_dir=$PWD

current_os=$(set +x; . /etc/os-release; echo ${ID})
current_os_version=$(set +x; . /etc/os-release; echo ${VERSION_ID})

if [ "$current_os" = "ubuntu" ]; then
    BUILD_DEPENDENCIES="$( set +x; echo \
        `# Required !` \
        build-essential \
        python \
        python-dev \
        curl \
        ca-certificates \
        gnupg \
        locales \
        pkg-config \
        libreadline-dev \
        zlib1g-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libjson-c-dev \
        libprotobuf-c-dev \
        libprotoc-dev \
        protobuf-compiler \
        protobuf-c-compiler \
        libsqlite3-dev\
        sqlite3 \
        llvm-dev \
        clang \
        uuid-dev \
      )"
    RUN_DEPENDENCIES="$( set +x; echo \
        `# Required !` \
        python \
        locales \
        libreadline7 \
        zlib1g \
        libssl1.0.0 \
        libxml2 \
        libxslt1.1 \
        libjson-c3 \
        libprotobuf-c1 \
        libprotoc10 \
        sqlite3 \
        llvm \
        uuid-dev \
      )"
elif [ "$current_os" = "debian" ]; then
    echo "here!"
else
    echo "Operating System `$current_os` not supported"
    exit 1
fi

# Update and apt-get basic packages
apt-get update \
    && apt-get install \
        -y \
        --no-install-recommends \
       $BUILD_DEPENDENCIES

# Download & untar sources

curl --progress-bar http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 | tar xj -C /usr/local/src/
curl --progress-bar http://download.osgeo.org/proj/proj-${PROJ4_VERSION}.tar.gz | tar xz -C /usr/local/src/
curl --progress-bar http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz | tar xz -C /usr/local/src/


# Compilation of GEOS
cd src/geos-${GEOS_VERSION}
    ./configure
    make -j "$(nproc)"
    make install
cd ../..
ldconfig

# Compilation of Proj4
cd src/proj-${PROJ4_VERSION}
    ./configure
    make -j "$(nproc)"
    make install
cd ../..
ldconfig

# Compilation of GDAL
cd src/gdal-${GDAL_VERSION}
    ./configure
    make -j "$(nproc)"
    make install
cd ../..
ldconfig

# Clean up
rm -rf /usr/local/src \
    /usr/local/share/doc* \
    /usr/local/share/man
apt-get remove \
    -y \
    --purge \
    --auto-remove \
    $BUILD_DEPENDENCIES

## Clean "a" files (Not required after compilation)
find /usr/local/lib/ -name '*.a' -delete

# Install run dependencies
apt-get install \
    -y \
    --no-install-recommends \
    $RUN_DEPENDENCIES

rm -rf /var/lib/apt/lists/*