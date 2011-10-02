#!/bin/bash

set -e -u

iso_name=march
iso_label="MARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=march
arch=$(uname -m)
work_dir=work
out_dir=out
verbose="y"

script_path=$(readlink -f ${0%/*})

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -p "$(grep -v ^# ${script_path}/packages.list)" create
}

# Customize installation (root-image)
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
	# copy march config
	cp -r ${script_path}/root-image ${work_dir}
	cp ${script_path}/sai_config ${work_dir}/root-image/sai/
	cp ${script_path}/packages.list ${work_dir}/root-image/sai/
	# change permission
	chmod 440 ${work_dir}/root-image/etc/sudoers
	chmod 755 ${work_dir}/root-image/install
	# setup rc.conf
	sed -i -e "s|^HOSTNAME=.*|HOSTNAME=localhost|" -e "s|^DAEMONS=.*|DAEMONS=(dbus kdm networkmanager cupsd)|" ${work_dir}/root-image/etc/rc.conf
	# setup pacman.conf
	sed -i -e "s|^#\[custom\]|[aur]|" -e "s|^#Server.*|Server = http://dl.dropbox.com/u/10527821/repo/i686|" ${work_dir}/root-image/etc/pacman.conf
	# remove unused manual and locale
	find ${work_dir}/root-image/usr/share/locale/* ! -name locale.alias | xargs rm -rf
	find ${work_dir}/root-image/usr/share/i18n/locales/* \
		! -name en_US \
		! -name en_GB \
		! -name i18n \
		! -name iso14651_t1* \
		! -name translit_* \
		| xargs rm -rf
	find ${work_dir}/root-image/usr/share/i18n/charmaps/* ! -name UTF-8.gz | xargs rm -rf
	rm -rf ${work_dir}/root-image/usr/share/X11/locale/
	rm -rf ${work_dir}/root-image/usr/share/man/
	rm -rf ${work_dir}/root-image/usr/share/doc/
	rm -rf ${work_dir}/root-image/usr/share/gtk-doc/
	rm -rf ${work_dir}/root-image/usr/share/licenses/
	rm -rf ${work_dir}/root-image/usr/share/kbd/locale/
	rm -rf ${work_dir}/root-image/usr/share/gtk-2.0/
	rm -rf ${work_dir}/root-image/usr/share/gtk-3.0/
	# remove unused app icon
	rm -f ${work_dir}/root-image/usr/share/applications/avahi-discover.desktop
	rm -f ${work_dir}/root-image/usr/share/applications/bssh.desktop
	rm -f ${work_dir}/root-image/usr/share/applications/bvnc.desktop
	# setup locale
	sed -i -e "s|^#en_US\.UTF-8|en_US.UTF-8|" ${work_dir}/root-image/etc/locale.gen
	chroot ${work_dir}/root-image locale-gen
	# setup mirrorlist
	sed -i -e "s|^#\(.*rit\.edu.*\)|\1|g" ${work_dir}/root-image/etc/pacman.d/mirrorlist
	# adduser
	chroot ${work_dir}/root-image/ usermod -p ZYCnDaw9NK8NI root
	chroot ${work_dir}/root-image/ useradd -m -p ZYCnDaw9NK8NI -g users \
		-G audio,lp,network,optical,power,storage,video,wheel march
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp /lib/initcpio/hooks/archiso ${work_dir}/root-image/lib/initcpio/hooks
        cp /lib/initcpio/install/archiso ${work_dir}/root-image/lib/initcpio/install
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        mkinitcpio \
            -c ${script_path}/mkinitcpio.conf \
            -b ${work_dir}/root-image \
            -k /boot/vmlinuz-linux \
            -g ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
        cp ${work_dir}/root-image/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
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
	convert -size 640x480 xc:black \
		-fill khaki1 -pointsize 120 -draw "text 100,200 'M'" \
		-fill grey -draw "text 210,200 'arch!'" \
		-pointsize 20 -draw "text 100,250 'Developer: #1331' \
		text 100,280 'Install: $ /install' \
		text 100,310 'Password: pass'" \
		-pointsize 12 -draw "text 540,20 '${iso_version}-${arch}'" \
		${work_dir}/iso/${install_dir}/boot/syslinux/splash.png
        cp ${work_dir}/root-image/usr/lib/syslinux/vesamenu.c32 ${work_dir}/iso/${install_dir}/boot/syslinux/
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

if [[ $verbose == "y" ]]; then
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
