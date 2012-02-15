source /etc/X11/xinit/xinitrc.d/30-dbus
# x resl
xrandr -s 1440x900 --output VGA2 --auto
# screen powersave
xset +dpms
xset dpms 0 0 300
# ENV
export EDITOR=geany
# wallpaper
feh --bg-fill ~/.wallpaper/wallpaper.jpg
# IM
export XMODIFIERS="@im=hime"
export GTK_IM_MODULE=hime
hime &
# DE
xcompmgr -cf &
(sleep 2s && tint2) &
exec openbox-session
