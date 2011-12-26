dbus-launch --sh-syntax --exit-with-session
# wallpaper
feh --bg-fill ~/.i3/wallpaper.jpg
# IM
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
fcitx &
# font
xset +fp /usr/share/fonts/wenquanyi
# i3
exec i3
