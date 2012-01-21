dbus-launch --sh-syntax --exit-with-session
# ENV
export EDITOR=geany
# wallpaper
feh --bg-fill ~/.i3/wallpaper.jpg
# general powersave
echo 5 | sudo tee /proc/sys/vm/laptop_mode
echo 1500 | sudo tee /proc/sys/vm/dirty_writeback_centisecs
echo powersave | sudo tee /sys/module/pcie_aspm/parameters/policy
xbacklight -set 50
# USB powersaving
for i in /sys/bus/usb/devices/*/power/autosuspend; do
	echo 1 | sudo tee $i
done
# SATA power saving
for i in /sys/class/scsi_host/host*/link_power_management_policy; do
	echo min_power | sudo tee $i
done
# IM
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
fcitx &
# font
xset +fp /usr/share/fonts/wenquanyi
# i3
exec i3
