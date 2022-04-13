# Copyright (c) 2006--2022, Yoshihiro Kawamata
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
# 
#   * Neither the name of the Yoshihiro Kawamata nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#========================================
# global definitions

PROJNAME =FuguIta
VERSION !=uname -r
ARCH    !=uname -m
DATE    !=date +%Y%m%d
REVISION!=if [ -r revcount_cdmaster ]; then cat revcount_cdmaster; else echo 0; fi

FI_FILENAME=$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$(REVISION)
#VERSTAT=beta
VERSTAT=
AUTHOR=KAWAMATA, Yoshihiro <kaw@on.rim.or.jp>

all:
	@echo /$(FI_FILENAME)/ - lets go


#========================================
# vncofig stuffs

open-all: open-rdroot open-media open-fuguita

close-all: close-fuguita close-media close-rdroot

open-rdroot:
	-vnconfig vnd0 rdroot.img
	-mount /dev/vnd0a rdroot

close-rdroot:
	-umount rdroot
	-vnconfig -u vnd0

open-media:
	-vnconfig vnd1 media.img
	-mount /dev/vnd1a media

close-media:
	-umount media
	-vnconfig -u vnd1

open-fuguita:
	-vnconfig vnd2 media/fuguita-$(VERSION)-$(ARCH).ffsimg
	-mount /dev/vnd2a fuguita

close-fuguita:
	-umount fuguita
	-vnconfig -u vnd2

#========================================
# contents syncing

sync:
	-make close-all
	make open-media
	make open-fuguita
	(cd staging && rsync -avxHS --delete . ../fuguita/.)

syncback:
	-make close-all
	make open-media
	make open-fuguita
	(cd fuguita && rsync -avxHS --delete . ../staging/.)

#========================================
# generate an ISO file

hyb:
	make open-fuguita
	echo "$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" > fuguita/usr/fuguita/version
	make close-fuguita

	mkhybrid -a -R -L -l -d -D -N \
		-o livecd.iso \
		-v -v \
		-A "FuguIta: OpenBSD-based Live System" \
		-P "Copyright (c) `date +%Y` KAWAMATA Yoshihiro" \
		-p "KAWAMATA Yoshihiro, http://fuguita.org/" \
		-V "$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" \
		-b cdbr \
		-c boot.catalog \
		media \
	&& echo $$(($(REVISION)+1)) > revcount_cdmaster

#========================================
# stuffs on kernel generation

boot: bsd bsd.mp lib/cdbr lib/cdboot
	cp lib/cdbr lib/cdboot media/.
	[ -d media/etc ] || mkdir media/etc
	cp lib/boot.conf media/etc/.

kern:
	(cd sys/arch/$(ARCH)/conf && config RDROOT)
	(cd sys/arch/$(ARCH)/compile/RDROOT && make obj && make)
	(cd sys/arch/$(ARCH)/conf && config RDROOT.MP)
	(cd sys/arch/$(ARCH)/compile/RDROOT.MP && make obj && make)

bsd: rdroot.img sys/arch/$(ARCH)/compile/RDROOT/obj/bsd
	cp sys/arch/$(ARCH)/compile/RDROOT/obj/bsd bsd
	rdsetroot bsd rdroot.img
	gzip -c9 bsd > media/bsd-fi

bsd.mp: rdroot.img sys/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd
	cp sys/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd bsd.mp
	rdsetroot bsd.mp rdroot.img
	gzip -c9 bsd.mp > media/bsd-fi.mp

#========================================
# packaging controls

iso:
	-make close-all
	make open-media
	make boot
	make hyb
	-make close-all

test:
	vmctl start -cL -i1 -m256M -r livecd.iso fitest

createimg:
	dd if=/dev/zero of=liveusb.img bs=1 count=0 seek=2G

testwithimg:
	vmctl start -cL -i1 -m256M -r livecd.iso -d liveusb.img fitest

gz:
	pv livecd.iso | gzip -9f -o $(FI_FILENAME)$(VERSTAT).iso.gz
	[ -f liveusb.img ] && pv liveusb.img | gzip -9f -o $(FI_FILENAME)$(VERSTAT).img.gz

reset:
	rm -f bsd bsd.mp livecd.iso liveusb.img FuguIta-?.?-*-*.iso.gz FuguIta-?.?-*-*.img.gz
	> revcount_cdmaster
