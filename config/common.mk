SUPERUSER_EMBEDDED := true

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

PRODUCT_PROPERTY_OVERRIDES += \
    keyguard.no_require_sim=true \
    ro.url.legal=http://www.google.com/intl/%s/mobile/android/basic/phone-legal.html \
    ro.url.legal.android_privacy=http://www.google.com/intl/%s/mobile/android/basic/privacy.html \
    ro.com.android.wifi-watchlist=GoogleGuest \
    ro.setupwizard.enterprise_mode=1 \
    ro.com.android.dateformat=MM-dd-yyyy \
    ro.com.android.dataroaming=false \
    ro.build.selinux=1 \
    persist.sys.root_access=3

# Disable multithreaded dexopt by default
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.dalvik.multithread=false

# Thank you, please drive thru!
PRODUCT_PROPERTY_OVERRIDES += persist.sys.dun.override=0

ifneq ($(TARGET_BUILD_VARIANT),eng)
# Enable ADB authentication
ADDITIONAL_DEFAULT_PROPERTIES += ro.adb.secure=1
endif

# Backup Tool
ifneq ($(WITH_GMS),true)
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/bin/backuptool.sh:system/bin/backuptool.sh \
    vendor/mahdi/prebuilt/common/bin/backuptool.functions:system/bin/backuptool.functions \
    vendor/mahdi/prebuilt/common/bin/50-mahdi.sh:system/addon.d/50-mahdi.sh \
    vendor/mahdi/prebuilt/common/bin/99-backup.sh:system/addon.d/99-backup.sh \
    vendor/mahdi/prebuilt/common/etc/backup.conf:system/etc/backup.conf
endif

# init.d support
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/etc/init.d/00banner:system/etc/init.d/00banner \
    vendor/mahdi/prebuilt/common/bin/sysinit:system/bin/sysinit

# userinit support
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit

# Mahdi-specific init file
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/etc/init.mahdi.rc:root/init.mahdi.rc

# Compcache/Zram support
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/bin/compcache:system/bin/compcache \
    vendor/mahdi/prebuilt/common/bin/handle_compcache:system/bin/handle_compcache \
    vendor/mahdi/prebuilt/common/etc/init.d/23zram:system/etc/init.d/23zram \
    vendor/mahdi/prebuilt/common/xbin/zon:system/xbin/zon \
    vendor/mahdi/prebuilt/common/xbin/zoff:system/xbin/zoff

# frandom support
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/lib/modules/frandom.ko:system/lib/modules/frandom.ko \
    vendor/mahdi/prebuilt/common/etc/init.d/22frandom:system/etc/init.d/22frandom \
    vendor/mahdi/prebuilt/common/xbin/ftest:system/xbin/ftest

# some basic init.d scripts
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/etc/init.d/01init:system/etc/init.d/01init \
    vendor/mahdi/prebuilt/common/etc/init.d/02sysctl:system/etc/init.d/02sysctl

# prebuilt omnirom compiled from carbonrom sources
PRODUCT_COPY_FILES += \
   vendor/mahdi/prebuilt/common/app/OmniSwitch.apk:system/app/OmniSwitch.apk

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Don't export PS1 in /system/etc/mkshrc.
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/etc/mkshrc:system/etc/mkshrc

# Gesture enabled JNI for IME
PRODUCT_COPY_FILES += \
    vendor/mahdi/prebuilt/common/lib/libjni_latinime.so:system/lib/libjni_latinime.so

# Theme engine
include vendor/mahdi/config/themes_common.mk

# Required Mahdi packages
PRODUCT_PACKAGES += \
    Development \
    LatinIME

# Optional Mahdi packages
PRODUCT_PACKAGES += \
    Apollo \
    libcyanogen-dsp \
    DSPManager \
    libemoji \
    LockClock \
    MahdiCenter \
    MahdiSetupWizard \
    ScreenRecorder \
    Trebuchet \
    CMHome

# Stock AOSP packages
PRODUCT_PACKAGES += \
    audio_effects.conf \
    Basic \
    libscreenrecorder \
    SoundRecorder \
    VoiceDialer \
    CellBroadcastReceiver

# Terminal Emulator
PRODUCT_COPY_FILES += \
    vendor/mahdi/proprietary/Term.apk:system/app/Term.apk \
    vendor/mahdi/proprietary/lib/armeabi/libjackpal-androidterm4.so:system/lib/libjackpal-androidterm4.so

# CM Hardware Abstraction Framework
PRODUCT_PACKAGES += \
    org.cyanogenmod.hardware \
    org.cyanogenmod.hardware.xml

# Extra tools in Mahdi
PRODUCT_PACKAGES += \
    libsepol \
    bash \
    openvpn \
    e2fsck \
    mke2fs \
    tune2fs \
    vim \
    nano \
    htop \
    powertop \
    lsof \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat \
    mkfs.f2fs \
    fsck.f2fs \
    fibmap.f2fs \
    ntfsfix \
    ntfs-3g \
    rsync \
    procmem \
    procrank \
    Superuser \
    su

# Openssh
PRODUCT_PACKAGES += \
    scp \
    sftp \
    ssh \
    sshd \
    sshd_config \
    ssh-keygen \
    start-ssh

PRODUCT_PACKAGE_OVERLAYS += vendor/mahdi/overlay/common
PRODUCT_PACKAGE_OVERLAYS += vendor/mahdi/overlay/dictionaries

# Inherit common product build prop overrides
-include vendor/mahdi/config/common_versions.mk

$(call inherit-product-if-exists, vendor/extra/product.mk)
