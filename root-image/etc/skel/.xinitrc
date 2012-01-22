dbus-launch --sh-syntax --exit-with-session
# screen powersave
xbacklight -set 20
xset +dpms
xset dpms 0 0 300
# ENV
export EDITOR=geany
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
