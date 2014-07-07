#!/bin/bash

set -e -u
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn rsync

iso_name=march
iso_label="MARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=install_dir
arch=$(uname -m)
work_dir=work
out_dir=out
# remove the old build
rm -rf "${work_dir}" "${out_dir}"
script_path=$(readlink -f ${0%/*})

# Helper function to run make_*() only one time per architecture.
run_once() {
    if [[ ! -e ${work_dir}/build.${1}_${arch} ]]; then
        $1
        touch ${work_dir}/build.${1}_${arch}
    fi
}

# Base installation (airootfs)
make_basefs() {
    git clone https://github.com/taylorchu/march-overlay.git ${work_dir}/march-overlay
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" init
    set +e
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -p "device-mapper sai-git $(grep -v ^# "${work_dir}/march-overlay/march/packages.list")" install
    set -e
}

# Customize installation (root-image)
make_customize_root_image() {
    # copy march config
    cp -r ${script_path}/root-image/ ${work_dir}
    cat ${work_dir}/march-overlay/march/{packages,extra}.list > ${work_dir}/root-image/sai/packages.list

    chmod 755 ${work_dir}/root-image/customize_image
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r '/customize_image' run
    rm ${work_dir}/root-image/customize_image
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    cp /usr/lib/initcpio/hooks/archiso ${work_dir}/airootfs/usr/lib/initcpio/hooks
    cp /usr/lib/initcpio/install/archiso ${work_dir}/airootfs/usr/lib/initcpio/install
    cp ${script_path}/mkinitcpio.conf ${work_dir}/airootfs/etc/mkinitcpio-archiso.conf
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' run
}

# Prepare ${install_dir}/boot/
make_boot() {
    mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
    cp ${work_dir}/airootfs/boot/archiso.img ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
    cp ${work_dir}/airootfs/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g;
         s|%ARCH%|${arch}|g" ${script_path}/syslinux/syslinux.cfg > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/${install_dir}/boot/syslinux/
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/menu.c32 ${work_dir}/iso/${install_dir}/boot/syslinux/
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/libutil.c32 ${work_dir}/iso/${install_dir}/boot/syslinux/
}

# Prepare /isolinux
make_isolinux() {
    mkdir -p ${work_dir}/iso/isolinux
    sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
    cp ${work_dir}/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/
}

# Build airootfs filesystem image
make_prepare() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${arch}.iso"
}

run_once make_basefs
run_once make_customize_root_image
run_once make_setup_mkinitcpio
run_once make_boot
run_once make_syslinux
run_once make_isolinux
run_once make_prepare
run_once make_iso
