dbus-launch --sh-syntax --exit-with-session
# screen powersave
xset +dpms
xset dpms 0 0 300
# ENV
export EDITOR=geany
# wallpaper
feh --bg-fill ~/.wallpaper/wallpaper.jpg
# IM
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
fcitx &
# DE
tint2 &
exec openbox-session
