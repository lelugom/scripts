# Upgrade TP-Link WDR3500 router

free
read -p "Check free RAM above. Continue (y/n)? " choice
case "$choice" in
    y|Y ) echo "Downloading files ...";;
    * ) echo "Unable to upgrade"; exit 0;;
esac

# Download image and checksums
cd /tmp
wget http://downloads.openwrt.org/snapshots/trunk/ar71xx/generic/md5sums
wget http://downloads.openwrt.org/snapshots/trunk/ar71xx/generic/openwrt-ar71xx-generic-tl-wdr3500-v1-squashfs-sysupgrade.bin

# Check the image integrity and upgrade router
if md5sum -c md5sums 2> /dev/null | grep OK; then
    sysupgrade -v /tmp/openwrt-ar71xx-generic-tl-wdr3500-v1-squashfs-sysupgrade.bin
else
    echo 'Unable to upgrade firmware. Bad image file'
fi

# Install software packages for printer server and monitoring
opkg update
opkg install p910nd kmod-usb-printer iftop htop bmon
