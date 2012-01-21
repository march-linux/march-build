dbus-launch --sh-syntax --exit-with-session
# ENV
export EDITOR=geany
# wallpaper
feh --bg-fill ~/.i3/wallpaper.jpg
# powersave
echo 1 | sudo tee /sys/devices/system/cpu/sched_mc_power_savings
echo 1 | sudo tee /sys/devices/system/cpu/sched_smt_power_savings
echo 1500 | sudo tee /proc/sys/vm/dirty_writeback_centisecs
echo 5 | sudo tee /proc/sys/vm/laptop_mode
echo powersave | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 10 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
xbacklight -set 50
# IM
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
fcitx &
# font
xset +fp /usr/share/fonts/wenquanyi
# i3
exec i3
