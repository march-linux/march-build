#!/bin/bash

set -e -u

name=march
iso_label="ARCH_$(date +%Y%m)"
version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
verbose="y"

script_path=$(readlink -f ${0%/*})

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -D "${install_dir}" -p "syslinux $(grep -v ^# ${script_path}/packages.list)" create "${work_dir}"
}

# Customize installation (root-image)
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
	# install aif
	make -f ${script_path}/aif/Makefile DESTDIR=${work_dir}/root-image install
	# copy march config
	cp -r ${script_path}/root-image ${work_dir}
	# copy aif config
	cp ${script_path}/march-profile ${work_dir}/root-image/march/
	cp ${script_path}/packages.list ${work_dir}/root-image/march/
	# change sudoers permission
	chmod 440 ${work_dir}/root-image/etc/sudoers
	# change march/setup permission
	chmod 755 ${work_dir}/root-image/march/setup
	# setup rc.conf
	sed -i -e "s|^DAEMONS=.*|DAEMONS=(dbus networkmanager gdm avahi-daemon cupsd)|" ${work_dir}/root-image/etc/rc.conf
	# remove unused manual and locale
	find ${work_dir}/root-image/usr/share/locale/* -maxdepth 0 ! -name locale.alias -exec rm -rf {} \;
	rm -rf ${work_dir}/root-image/usr/share/X11/locale/
	rm -rf ${work_dir}/root-image/usr/share/man/
	rm -rf ${work_dir}/root-image/usr/share/doc/
	rm -rf ${work_dir}/root-image/usr/share/gtk-doc/
	rm -rf ${work_dir}/root-image/usr/share/licenses/
	rm -rf ${work_dir}/root-image/usr/share/kbd/locale/
	rm -rf ${work_dir}/root-image/usr/share/gnome/help/
	rm -rf ${work_dir}/root-image/usr/share/gtk-2.0/
	rm -rf ${work_dir}/root-image/usr/share/gtk-3.0/
	# adduser and setup locale
	chroot ${work_dir}/root-image/ locale-gen
	chroot ${work_dir}/root-image/ usermod -p ZYCnDaw9NK8NI root
	chroot ${work_dir}/root-image/ useradd -m -p ZYCnDaw9NK8NI -g users -G audio,lp,network,optical,power,storage,video,wheel march
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
	cp ${script_path}/syslinux/splash.png ${work_dir}/iso/${install_dir}/boot/syslinux/
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
    mkarchiso ${verbose} -D "${install_dir}" prepare "${work_dir}"
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -D "${install_dir}" checksum "${work_dir}"
    mkarchiso ${verbose} -D "${install_dir}" -L "${iso_label}" iso "${work_dir}" "${name}-${version}-${arch}.iso"
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

