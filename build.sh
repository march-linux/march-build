#!/bin/bash

set -e -u
# dep: make imagemagick ttf-droid squashfs-tools libisoburn

iso_name=march
iso_label="MARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=march
arch=$(uname -m)
work_dir=work
out_dir=out
verbose="y"

script_path=$(cd $(dirname "$0"); pwd)

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" init
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -p "device-mapper sai $(grep -v ^# ${script_path}/packages.list)" install
}

# Customize installation (root-image)
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
	# copy march config
	cp -r ${script_path}/root-image/ ${work_dir}
	cp ${script_path}/packages.list ${work_dir}/root-image/sai/
	cp -r ${script_path}/root-image/etc/ ${work_dir}/root-image/sai/
	# change permission
	chmod 440 ${work_dir}/root-image/etc/sudoers
	chmod 755 ${work_dir}/root-image/install
	# remove unused manual
	rm -rf ${work_dir}/root-image/usr/share/man/
	rm -rf ${work_dir}/root-image/usr/share/doc/
	rm -rf ${work_dir}/root-image/usr/share/gtk-doc/
	rm -rf ${work_dir}/root-image/usr/share/licenses/
	rm -rf ${work_dir}/root-image/usr/share/info/
	rm -rf ${work_dir}/root-image/usr/share/gtk-2.0/
	rm -rf ${work_dir}/root-image/usr/share/gtk-3.0/
	# setup mirrorlist
	sed -i -e 's|^#\(.*http://.*\.kernel\.org.*\)|\1|' ${work_dir}/root-image/etc/pacman.d/mirrorlist
	# adduser
	chroot ${work_dir}/root-image/ usermod -p ZYCnDaw9NK8NI root
	chroot ${work_dir}/root-image/ useradd -m -p ZYCnDaw9NK8NI -g users \
		-G audio,lp,network,optical,power,storage,video,wheel march
	# setup locale
    	sed -i -e 's|^#\(en_US\.UTF-8\)|\1|'  ${work_dir}/root-image/etc/locale.gen
	chroot ${work_dir}/root-image locale-gen
    	# add march repo
	echo "[march]" >> ${work_dir}/root-image/etc/pacman.conf
	echo "Server = http://dl.dropbox.com/u/10527821/repo/x86_64/" >> ${work_dir}/root-image/etc/pacman.conf
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp /usr/lib/initcpio/hooks/archiso ${work_dir}/root-image/usr/lib/initcpio/hooks
        cp /usr/lib/initcpio/install/archiso ${work_dir}/root-image/usr/lib/initcpio/install
        cp ${script_path}/mkinitcpio.conf ${work_dir}/root-image/etc/mkinitcpio-archiso.conf
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" \
            -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' \
            run
        mv ${work_dir}/root-image/boot/archiso.img ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
        mv ${work_dir}/root-image/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%INSTALL_DIR%|${install_dir}|g;
            s|%ARCH%|${arch}|g" ${script_path}/syslinux/syslinux.cfg > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
	convert ${work_dir}/root-image/etc/skel/.wallpaper/wallpaper.jpg -resize 640x480^ -gravity center -extent 640x480 \
		-font Droid-Sans-Mono-Regular -fill white -pointsize 12 -draw "text 250,220 '${iso_version}-${arch}'" \
		${work_dir}/iso/${install_dir}/boot/syslinux/splash.jpg
        cp ${work_dir}/root-image/usr/lib/syslinux/{vesamenu.c32,chain.c32,reboot.c32,poweroff.com} ${work_dir}/iso/${install_dir}/boot/syslinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /isolinux
make_isolinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/isolinux
        sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/isohdpfx.bin ${work_dir}/iso/isolinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Process aitab
make_aitab() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        sed "s|%ARCH%|${arch}|g" ${script_path}/aitab > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" checksum
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${arch}.iso"
}

if [[ ${verbose} == "y" ]]; then
    verbose="-v"
else
    verbose=""
fi

make_basefs
make_customize_root_image
make_setup_mkinitcpio
make_boot
make_syslinux
make_isolinux
make_aitab
make_prepare
make_iso
