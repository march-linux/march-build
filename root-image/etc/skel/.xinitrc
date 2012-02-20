source /etc/X11/xinit/xinitrc.d/30-dbus
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
tint2 &
exec openbox-session
