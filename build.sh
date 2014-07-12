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

options="i915.i915_enable_rc6=7 i915.i915_enable_fbc=1 i915.lvds_downclock=1 pcie_aspm=force radeon.modeset=0 i915.modeset=1 i915.lvds_channel_mode=2"

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
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -p "device-mapper sai-git prebootloader gummiboot $(grep -v ^# "${work_dir}/march-overlay/march/packages.list")" install
    set -e
}

# Customize installation (airootfs)
make_customize_airootfs() {
    # copy march config
    cp -r ${script_path}/airootfs/ ${work_dir}
    cat ${work_dir}/march-overlay/march/{packages,extra}.list > ${work_dir}/airootfs/sai/packages.list

    chmod 755 ${work_dir}/airootfs/customize_image
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r '/customize_image' run
    rm ${work_dir}/airootfs/customize_image
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
         s|%ARCHISO_OPTIONS%|${options}|g;
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

# Prepare /EFI
make_efi() {
    mkdir -p ${work_dir}/iso/EFI/boot
    cp ${work_dir}/airootfs/usr/lib/prebootloader/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
    cp ${work_dir}/airootfs/usr/lib/prebootloader/HashTool.efi ${work_dir}/iso/EFI/boot/

    cp ${work_dir}/airootfs/usr/lib/gummiboot/gummibootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

    mkdir -p ${work_dir}/iso/loader/entries
    cp ${script_path}/efiboot/loader/loader.conf ${work_dir}/iso/loader/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%ARCHISO_OPTIONS%|${options}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        ${script_path}/efiboot/loader/entries/archiso-x86_64-usb.conf > ${work_dir}/iso/loader/entries/archiso-x86_64.conf

    # EFI Shell 2.0 for UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=UEFI_Shell )
    curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://svn.code.sf.net/p/edk2/code/trunk/edk2/ShellBinPkg/UefiShell/X64/Shell.efi
    # EFI Shell 1.0 for non UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Efi-shell )
    curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://svn.code.sf.net/p/edk2/code/trunk/edk2/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {
    mkdir -p ${work_dir}/iso/EFI/archiso
    truncate -s 31M ${work_dir}/iso/EFI/archiso/efiboot.img
    mkfs.vfat -n ARCHISO_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

    mkdir -p ${work_dir}/efiboot
    mount ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

    mkdir -p ${work_dir}/efiboot/EFI/archiso
    cp ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
    cp ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img ${work_dir}/efiboot/EFI/archiso/archiso.img

    mkdir -p ${work_dir}/efiboot/EFI/boot
    cp ${work_dir}/airootfs/usr/lib/prebootloader/PreLoader.efi ${work_dir}/efiboot/EFI/boot/bootx64.efi
    cp ${work_dir}/airootfs/usr/lib/prebootloader/HashTool.efi ${work_dir}/efiboot/EFI/boot/

    cp ${work_dir}/airootfs/usr/lib/gummiboot/gummibootx64.efi ${work_dir}/efiboot/EFI/boot/loader.efi

    mkdir -p ${work_dir}/efiboot/loader/entries
    cp ${script_path}/efiboot/loader/loader.conf ${work_dir}/efiboot/loader/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%ARCHISO_OPTIONS%|${options}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        ${script_path}/efiboot/loader/entries/archiso-x86_64-cd.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf

    cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
    cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

    umount ${work_dir}/efiboot
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
run_once make_customize_airootfs
run_once make_setup_mkinitcpio
run_once make_boot
run_once make_syslinux
run_once make_isolinux
run_once make_efi
run_once make_efiboot
run_once make_prepare
run_once make_iso
