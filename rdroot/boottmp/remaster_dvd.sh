#!/bin/sh

#----------------------------------------
# remaster_dvd.sh - Remastering FuguIta's LiveDVD
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: remaster_dvd.sh,v 1.3 2022/08/11 02:56:30 kaw Exp $
#----------------------------------------

# Copyright (c) 2006--2022
# Yoshihiro Kawamata
#
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
#   * Neither the name of Yoshihiro Kawamata nor the names of its
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

# parameters
#
projname=FuguIta
 version=$(uname -r)
    arch=$(uname -m)
    date=$(date +%Y%m%d)
     rev=1

# files to be remastered
#
files=$(cat<<EOT
./boot
./boot.catalog
./bsd-fi
./bsd-fi.mp
./cdboot
./cdbr
./etc/boot.conf
./etc/random.seed
./$(echo ${projname} | tr A-Z a-z)-${version}-${arch}.ffsimg
EOT)

# check contents
#
if [ "$files" != "$(find . -type f -print | sort)" ]; then
    echo "$0: it doesn't seem to be ${projname}'s dir:" >&2
    echo '  shouldbe:' $files
    echo '  reallyis:' $(find . -type f -print | sort)
    exit 1
fi

# do remastering
#
mkhybrid -a -R -L -l -d -D -N \
                -o ../${projname}-${version}-${arch}-${date}${rev}.iso \
                -v -v \
                -A "FuguIta - OpenBSD Live System" \
                -P "Copyright (c) `date +%Y` Yoshihiro Kawamata" \
                -p "Yoshihiro Kawamata, https://fuguita.org/" \
                -V "${projname}-${version}-${arch}-${date}${rev}" \
                -b cdbr \
                -c boot.catalog \
                .
