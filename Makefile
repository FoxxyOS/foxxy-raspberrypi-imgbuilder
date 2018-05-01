#!/bin/sh

# (C) 2012-2015 Fathi Boudra <fathi.boudra@linaro.org>

# (C) 2015-2017 Francesco Bonanno <mibofra@frozenbox.org> , little changes for foxxy arm rootfs tarballs.

# Calls all necessary live-build programs in the correct order to complete
# the bootstrap, chroot, binary, and source stage.

# You need live-build package installed and superuser privileges.

BUILD_NUMBER=1
BASEIMG=foxxysec-standard-3.7-armhf-rpi
IMAGEPREFIX=$(BASEIMG)-$(BUILD_NUMBER)
LOGFILE=$(IMAGEPREFIX).build-log.txt
LOGFILEIMG=$(IMAGEPREFIX).build-log-img.txt
CONFIGFILE=$(IMAGEPREFIX).config.tar.bz2
LISTFILE=$(IMAGEPREFIX).contents
CHROOTFILE=$(IMAGEPREFIX).files
PKGSFILE=$(IMAGEPREFIX).packages
TARGZFILE=$(IMAGEPREFIX).tar.gz
MD5SUMSFILE=$(IMAGEPREFIX).md5sums.txt
SHA1SUMSFILE=$(IMAGEPREFIX).sha1sums.txt
IMAGENAME=$(IMAGEPREFIX).img
MD5SUMIMG=$(IMAGENAME).md5sum.txt
SHA1SUMIMG=$(IMAGENAME).sha1sum.txt
TARXZFILE=$(IMAGENAME).tar.xz
MD5SUMTARXZFILE=$(TARXZFILE).md5sum.txt
SHA1SUMTARXZFILE=$(TARXZFILE).sha1sum.txt
BLOCKDEVICE=

all:
	set -e; sudo lb build 2>&1 | tee $(LOGFILE)
	if [ -f live-image-armhf.tar.tar.gz ]; then \
		tar -jcf $(CONFIGFILE) auto/ config/ configure; \
		sudo mv live-image-armhf.contents $(LISTFILE); \
		sudo mv chroot.files $(CHROOTFILE); \
		sudo mv chroot.packages.install $(PKGSFILE); \
		sudo mv live-image-armhf.tar.tar.gz $(TARGZFILE); \
		md5sum $(LOGFILE) $(CONFIGFILE) $(LISTFILE) $(CHROOTFILE) $(PKGSFILE) $(TARGZFILE) > $(MD5SUMSFILE); \
		sha1sum $(LOGFILE) $(CONFIGFILE) $(LISTFILE) $(CHROOTFILE) $(PKGSFILE) $(TARGZFILE) > $(SHA1SUMSFILE); \
		set -e; sudo ./build_foxxysec_image.sh 2>&1 | tee $(LOGFILEIMG); \
	fi

	if [ -f foxxysec-rpi/foxxy-armhf-image.img ]; then \
		sudo mv foxxysec-rpi/foxxy-armhf-image.img $(IMAGENAME); \
		sudo mv foxxysec-rpi/foxxy-armhf-image.img.md5sum.txt $(MD5SUMIMG); \
		sudo mv foxxysec-rpi/foxxy-armhf-image.img.sha1sum.txt $(SHA1SUMIMG); \
		sleep 1; \
		XZ_OPT=-9 tar cfJ $(TARXZFILE) $(IMAGENAME) $(MD5SUMIMG) $(SHA1SUMIMG) $(LOGFILEIMG); \
		sudo rm -rf $(IMAGENAME) $(MD5SUMIMG) $(SHA1SUMIMG) $(LOGFILEIMG); \
		md5sum $(TARXZFILE) > $(MD5SUMTARXZFILE); \
		sha1sum $(TARXZFILE) > $(SHA1SUMTARXZFILE); \
	fi

finalize:
	if [ -f live-image-armhf.tar.tar.gz ]; then \
		tar -jcf $(CONFIGFILE) auto/ config/ configure; \
		sudo mv live-image-armhf.contents $(LISTFILE); \
		sudo mv chroot.files $(CHROOTFILE); \
		sudo mv chroot.packages.install $(PKGSFILE); \
		sudo mv live-image-armhf.tar.tar.gz $(TARGZFILE); \
		md5sum $(LOGFILE) $(CONFIGFILE) $(LISTFILE) $(CHROOTFILE) $(PKGSFILE) $(TARGZFILE) > $(MD5SUMSFILE); \
		sha1sum $(LOGFILE) $(CONFIGFILE) $(LISTFILE) $(CHROOTFILE) $(PKGSFILE) $(TARGZFILE) > $(SHA1SUMSFILE); \
	fi

clean:
	sudo lb clean --purge
	rm -f $(BASEIMG)-*
	rm -rf config
	rm -rf .build

	if [ -d foxxysec-rpi ]; then \
		sudo umount -l foxxysec-rpi/*; true; \
		sudo dmsetup remove_all; \
		sudo rm -rf foxxysec-rpi; \
		sudo rm -rf rpi-firmware; true; \
	fi

	if [ -f $(IMAGENAME) ]; then \
		rm -f $(IMAGENAME)*; \
		sudo umount -l foxxysec-rpi/*; true; \
		sudo dmsetup remove_all; \
		sudo rm -rf foxxysec-rpi rpi-firmware; \
	fi

write-image:
	sudo ./build_foxxysec_image.sh $(BLOCKDEVICE)

write-and-resize:
	sudo ./image-writer-resizer.sh $(BLOCKDEVICE)
