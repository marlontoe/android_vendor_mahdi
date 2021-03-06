#!/bin/bash

# Android AOSP/AOSPA/CM/SLIM/MAHDI build script
# Version 2.0.12

# Clean scrollback buffer
echo -e '\0033\0143'
clear

# Get current path
DIR="$(cd `dirname $0`; pwd)"
OUT="$(readlink $DIR/out)"
[ -z "${OUT}" ] && OUT="${DIR}/out"

# Prepare output customization commands
red=$(tput setaf 1)             # red
grn=$(tput setaf 2)             # green
blu=$(tput setaf 4)             # blue
cya=$(tput setaf 6)             # cyan
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) # green
bldblu=${txtbld}$(tput setaf 4) # blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtbld=$(tput bold)             # bold
txtrst=$(tput sgr0)             # reset

# Local defaults, can be overriden by environment
: ${PREFS_FROM_SOURCE:="false"}
: ${WITHOUT_PROP_APPS:="true"}
: ${WITHOUT_MC:="true"}
: ${USE_CCACHE:="true"}
: ${CCACHE_NOSTATS:="false"}
: ${CCACHE_DIR:="$(dirname ~/.ccache"}
: ${THREADS:="$(cat /proc/cpuinfo | grep "^processor" | wc -l)"}

# If there is more than one jdk installed, use latest 6.x
if [ "`update-alternatives --list javac | wc -l`" -gt 1 ]; then
        JDK6=$(dirname `update-alternatives --list javac | grep "\-6\-"` | tail -n1)
        JRE6=$(dirname ${JDK6}/../jre/bin/java)
        export PATH=${JDK6}:${JRE6}:$PATH
fi
JVER=$(javac -version  2>&1 | head -n1 | cut -f2 -d' ')

# Import command line parameters
DEVICE="$1"
EXTRAS="$2"

# Get build version
if [ -r ${DIR}/vendor/pa/vendor.mk ]; then
        VENDOR="aospa"
        VENDOR_LUNCH="pa_"
        MAJOR=$(cat ${DIR}/vendor/pa/vendor.mk | grep 'ROM_VERSION_MAJOR := *' | sed  's/ROM_VERSION_MAJOR := //g')
        MINOR=$(cat ${DIR}/vendor/pa/vendor.mk | grep 'ROM_VERSION_MINOR := *' | sed  's/ROM_VERSION_MINOR := //g')
        MAINT=$(cat ${DIR}/vendor/pa/vendor.mk | grep 'ROM_VERSION_MAINTENANCE := *' | sed  's/ROM_VERSION_MAINTENANCE := //g')
elif [ -r ${DIR}/vendor/slim/vendorsetup.sh ]; then
        VENDOR="slim"
        VENDOR_LUNCH="slim_"
        MAJOR=$(cat ${DIR}/vendor/slim/config/common.mk | grep 'PRODUCT_VERSION_MAJOR = *' | sed  's/PRODUCT_VERSION_MAJOR = //g')
        MINOR=$(cat ${DIR}/vendor/slim/config/common.mk | grep 'PRODUCT_VERSION_MINOR = *' | sed  's/PRODUCT_VERSION_MINOR = //g')
        MAINT=$(cat ${DIR}/vendor/slim/config/common.mk | grep 'PRODUCT_VERSION_MAINTENANCE = *' | sed  's/PRODUCT_VERSION_MAINTENANCE = //g')
elif [ -r vendor/cm/config/common.mk ]; then
        VENDOR="cm"
        VENDOR_LUNCH=""
        MAJOR=$(cat ${DIR}/vendor/cm/config/common.mk | grep 'PRODUCT_VERSION_MAJOR = *' | sed  's/PRODUCT_VERSION_MAJOR = //g')
        MINOR=$(cat ${DIR}/vendor/cm/config/common.mk | grep 'PRODUCT_VERSION_MINOR = *' | sed  's/PRODUCT_VERSION_MINOR = //g')
        MAINT=$(cat ${DIR}/vendor/cm/config/common.mk | grep 'PRODUCT_VERSION_MAINTENANCE = *' | sed  's/PRODUCT_VERSION_MAINTENANCE = //g')
elif [ -r vendor/mahdi/config/common.mk ]; then
        VENDOR="mahdi"
        VENDOR_LUNCH=""
        MAJOR=$(cat ${DIR}/vendor/mahdi/config/common_versions.mk | grep 'PRODUCT_VERSION_MAJOR = *' | sed  's/PRODUCT_VERSION_MAJOR = //g')
        MINOR=$(cat ${DIR}/vendor/mahdi/config/common_versions.mk | grep 'PRODUCT_VERSION_MINOR = *' | sed  's/PRODUCT_VERSION_MINOR = //g')
        MAINT=$(cat ${DIR}/vendor/mahdi/config/common_versions.mk | grep 'PRODUCT_VERSION_MAINTENANCE = *' | sed  's/PRODUCT_VERSION_MAINTENANCE = //g')
elif [ -r ${DIR}/build/core/version_defaults.mk ]; then
        VENDOR="aosp"
        VENDOR_LUNCH="full_"
        MAJOR=$(cat ${DIR}/build/core/version_defaults.mk | grep 'PLATFORM_VERSION := *' | awk '{print $3}' | cut -f2 -d= | cut -f1 -d.)
        MINOR=$(cat ${DIR}/build/core/version_defaults.mk | grep 'PLATFORM_VERSION := *' | awk '{print $3}' | cut -f2 -d= | cut -f2 -d.)
        MAINT=$(cat ${DIR}/build/core/version_defaults.mk | grep 'PLATFORM_VERSION := *' | awk '{print $3}' | cut -f2 -d= | cut -f3 -d.)
else
        echo -e "${redbld}Invalid android tree, exiting...${txtrst}"
        exit 1
fi
VERSION=$VENDOR-$MAJOR.$MINOR$([ -n "$MAINT" ] && echo .)$MAINT

# If there is no extra parameter, reduce parameters index by 1
if [ "$EXTRAS" == "true" ] || [ "$EXTRAS" == "false" ]; then
        SYNC="$2"
        UPLOAD="$3"
else
        SYNC="$3"
        UPLOAD="$4"
fi

# Get start time
res1=$(date +%s.%N)

# Prepare ccache and get it's initial size for reference
if [ "${USE_CCACHE}" == "true" ]; then
        # Prefer system ccache with compression
        CCACHE="$(which ccache)"
        if [ -n "${CCACHE}" ]; then
                export CCACHE_COMPRESS="1"
                echo -e "${bldblu}Using system ccache with compression enabled [${CCACHE}]${txtrst}"
        elif [ -r "${DIR}/prebuilts/misc/linux-x86/ccache/ccache" ]; then
                CCACHE="${DIR}/prebuilts/misc/linux-x86/ccache/ccache"
                echo -e "${bldblu}Using prebuilt ccache [${CCACHE}]${txtrst}"
        else
                echo -e "${bldblu}No suitable ccache found, disabling ccache usage${txtrst}"
                unset USE_CCACHE
                unset CCACHE_DIR
                unset CCACHE_NOSTATS
                unset CCACHE
        fi

        if [ -n "${CCACHE}" ]; then
                # Prepare ccache parameter for make
                CCACHE_OPT="ccache=${CCACHE}"

                # If custom ccache folder not specified, will use default one
                #[ -n "${CCACHE_DIR}" ] || CCACHE_DIR="${HOME}/.ccache"

                # Export and prepare ccache storage
                export CCACHE_DIR
                if [ ! -d "${CCACHE_DIR}" ]; then
                        mkdir -p "${CCACHE_DIR}"
                        chmod ug+rwX "${CCACHE_DIR}"
                        ${CCACHE} -C -M 5G
                        cache1=0
                fi
        fi

        # Save ccache size before build
        if [ -z "${cache1}" ]; then
                if [ "${CCACHE_NOSTATS}" == "true" ]; then
                        cache1=$(du -sh ${CCACHE_DIR} | awk '{print $1}')
                else
                        cache1=$(${CCACHE} -s | grep "^cache size" | awk '{print $3$4}')
                fi
        fi
else
        # Clean environment if ccache is not enabled
        unset USE_CCACHE
        unset CCACHE_OPT
        unset CCACHE_DIR
        unset CCACHE_NOSTATS
        unset CCACHE
fi

echo -e "${cya}Building ${bldcya}Android $VERSION for $DEVICE using Java-$JVER${txtrst}";
echo -e "${bldgrn}Start time: $(date) ${txtrst}"

# Print ccache stats
[ -n "${USE_CCACHE}" ] && export USE_CCACHE && echo -e "${cya}Building using CCACHE${txtrst}"
[ -n "${CCACHE_DIR}" ] && export CCACHE_DIR && echo -e "${bldgrn}CCACHE: location = [${txtrst}${grn}${CCACHE_DIR}${bldgrn}], size = [${txtrst}${grn}${cache1}${bldgrn}]${txtrst}"

# Decide what command to execute
case "$EXTRAS" in
        threads)
                echo -e "${bldblu}Please enter desired building/syncing threads number followed by [ENTER]${txtrst}"
                read threads
                THREADS=$threads
        ;;
        clean|cclean)
                echo -e "${bldblu}Cleaning intermediates and output files${txtrst}"
                export CLEAN_BUILD="true"
                [ -d "${DIR}/out" ] && rm -Rf ${DIR}/out/*
                # Clean ccache if we have to
                if [ -n "${CCACHE_DIR}" ] && [ $EXTRAS == cclean ]; then
                        echo "${bldblu}Cleaning ccache${txtrst}"
                        ${CCACHE} -C -M 5G
                fi
        ;;
esac

echo -e ""

# Fetch latest sources
if [ "$SYNC" == "true" ]; then
        echo -e "\n${bldblu}Fetching latest sources${txtrst}"
        repo sync -j"$THREADS"
fi

# Print java caveats
if [ ! -r "${DIR}/out/versions_checked.mk" ] && [ -n "$(java -version 2>&1 | grep -i openjdk)" ]; then
        echo -e "\n${bldcya}Your java version still not checked and is candidate to fail, masquerading.${txtrst}"
        JAVA_VERSION="java_version=${JVER}"
fi

if [ -r ${DIR}/build/addons/blobs.sh ]; then
        if [ -r ${DIR}/build/addons/blobs/.blobs.stamp ]; then
                echo -e "${bldgrn}Already downloaded blobs${txtrst}"
        else
                echo -e "${bldblu}Fetching blobs${txtrst}"
                pushd ${DIR}/build/addons/blobs > /dev/null
                source ./blobs.sh && touch ${DIR}/build/addons/blobs/.blobs.stamp
                popd > /dev/null
        fi
elif [ -r ${DIR}/vendor/${VENDOR}/get-prebuilts ]; then
        if [ -r ${DIR}/vendor/${VENDOR}/proprietary/.get-prebuilts ]; then
                echo -e "${bldgrn}Already downloaded prebuilts${txtrst}"
        else
                echo -e "${bldblu}Downloading prebuilts${txtrst}"
                pushd ${DIR}/vendor/${VENDOR} > /dev/null
                source ./get-prebuilts && touch proprietary/.get-prebuilts
                popd > /dev/null
        fi
else
        echo -e "${bldcya}No prebuilts script in this tree${txtrst}"
fi

# Export global variables for buildsystem
export PREFS_FROM_SOURCE
export WITHOUT_PROP_APPS
export WITHOUT_MC

# Decide if we enter interactive mode or default build mode
if [ -n "${INTERACTIVE}" ]; then
        echo -e "\n${bldblu}Enabling interactive mode. Possible commands are:${txtrst}"

        if [ "${VENDOR}" == "cm" ] || [ "${VENDOR}" == "mahdi" ]; then
                echo -e "To prepare device environment:[${bldgrn}breakfast ${VENDOR_LUNCH}${DEVICE}${txtrst}]"
        else
                echo -e "To prepare device environment:[${bldgrn}lunch ${VENDOR_LUNCH}${DEVICE}-userdebug${txtrst}]"
        fi

        if [ "${VENDOR}" == "aosp" ]; then
                echo -e "To build device:[${bldgrn}make otapackage${txtrst}]"
        else
                echo -e "To build device:[${bldgrn}mka bacon${txtrst}]"
        fi

        echo -e "To see all make commands:[${bldgrn}make help${txtrst}]"
        echo -e "To emulate device:[${bldgrn}vncserver :1; DISPLAY=:1 emulator&${txtrst}]"
        echo -e "You may try to prefix make commands with:[${bldgrn}schedtool -B -n 1 -e ionice -n 1${txtrst}]"
        echo -e "You may try to suffix make commands with:[${bldgrn}-j${THREADS} ${CCACHE_OPT} ${JAVA_VERSION}${txtrst}]"

        # Setup and enter interactive environment
        echo -e "${bldblu}Dropping to interactive shell...${txtrst}"
        bash --init-file ${DIR}/build/envsetup.sh -i
else
        # Setup environment
        echo -e "\n${bldblu}Setting up environment${txtrst}"
        . build/envsetup.sh

        # Preparing
        echo -e "\n${bldblu}Preparing device [${DEVICE}]${txtrst}"
        if [ "${VENDOR}" == "cm" ] || [ "${VENDOR}" == "mahdi" ]; then
                breakfast "${VENDOR_LUNCH}${DEVICE}"
        else
                lunch "${VENDOR_LUNCH}${DEVICE}-userdebug"
        fi

        echo -e "${bldblu}Starting compilation${txtrst}"
        if [ "${VENDOR}" == "aosp" ]; then
                schedtool -B -n 1 -e ionice -n 1 make -j${THREADS} ${CCACHE_OPT} ${JAVA_VERSION} otapackage
        elif [ "${VENDOR}" == "cm" ] || [ "${VENDOR}" == "mahdi" ]; then
                brunch "${VENDOR_LUNCH}${DEVICE}"
        else
                mka bacon
        fi
fi

# Get and print increased ccache size
if [ -n "${CCACHE_DIR}" ]; then
        if [ "${CCACHE_NOSTATS}" == "true" ]; then
                cache2=$(du -sh ${CCACHE_DIR} | awk '{print $1}')
        else
                cache2=$(prebuilts/misc/linux-x86/ccache/ccache -s | grep "^cache size" | awk '{print $3$4}')
        fi
                echo -e "\n${bldgrn}ccache size is ${txtrst} ${grn}${cache2}${txtrst} (was ${grn}${cache1}${txtrst})"
fi

# Get and print elapsed time
res2=$(date +%s.%N)
echo -e "\n${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds)${txtrst}"
