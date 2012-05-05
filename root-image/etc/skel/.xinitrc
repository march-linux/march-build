source /etc/X11/xinit/xinitrc.d/30-dbus
# screen powersave
xset +dpms
xset dpms 0 0 300
# ENV
export EDITOR="urxvt -e vim"
# wallpaper
feh --bg-fill ~/.wallpaper/wallpaper.jpg
# IM
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
fcitx &
# DE
xset +fp /usr/share/fonts/wenquanyi
exec i3
