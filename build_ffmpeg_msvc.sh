#!/bin/sh

arch=x86
archdir=Win32
clean_build=true

for opt in "$@"
do
    case "$opt" in
    x86)
            ;;
    arm)
            arch=arm
            archdir=arm
            ;;
    quick)
            clean_build=false
            ;;
    *)
            echo "Unknown Option $opt"
            exit 1
    esac
done

make_dirs() (
  if [ ! -d bin_${archdir}d/lib ]; then
    mkdir -p bin_${archdir}d/lib
  fi
)

copy_libs() (
  cp lib*/*.dll bin_${archdir}d
  cp lib*/*.pdb bin_${archdir}d
  cp lib*/*.lib bin_${archdir}d/lib
)

clean() (
  make distclean > /dev/null 2>&1
)

configure() (
  OPTIONS="
    --enable-shared                 \
    --disable-static                \
    --enable-gpl                    \
    --enable-w32threads             \
    --enable-winrtapi               \
    --disable-devices               \
    --disable-filters               \
    --disable-protocols             \
    --enable-network                \
    --disable-muxers                \
    --disable-hwaccels              \
    --enable-avresample             \
    --disable-encoders              \
    --disable-programs              \
    --enable-debug                  \
    --disable-doc                   \
    --enable-cross-compile          \
    --target-os=win32"

  EXTRA_CFLAGS="-D_WIN32_WINNT=0x0602 -MDd -D_WINAPI_FAMILY=WINAPI_FAMILY_APP"
  EXTRA_LDFLAGS="-NODEFAULTLIB:libcmt"

case "$arch"  in
    x86)
        OPTIONS+="
            --arch=x86                      \
            --as=yasm"
            ;;
    arm)
        OPTIONS+="    
            --arch=arm                      \
            --cpu=armv7-a                   \
            --as=armasm                     \
            --enable-thumb"
        EXTRA_CFLAGS+=" -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE  -D__ARM_PCS_VFP -D_ARM_"
            ;;
esac
  sh configure --toolchain=msvc --enable-debug --extra-cflags="${EXTRA_CFLAGS}" --extra-ldflags="${EXTRA_LDFLAGS}" ${OPTIONS}
)

build() (
  make 
)

echo Building ffmpeg in MSVC Debug config...

make_dirs

#cd flvchangedffmpeg
 
if $clean_build ; then
    clean

    ## run configure, redirect to file because of a msys bug
    configure > config.out 2>&1
    CONFIGRETVAL=$?
    
    
    ## show configure output
    cat config.out
fi

## Only if configure succeeded, actually build
if ! $clean_build || [ ${CONFIGRETVAL} -eq 0 ]; then
  build &&
  copy_libs
fi

cd ..
