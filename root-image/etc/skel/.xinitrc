source /etc/X11/xinit/xinitrc.d/30-dbus
# screen powersave
xset +dpms
xset dpms 0 0 300
# ENV
export EDITOR="urxvt -e vim"
# IM
export XMODIFIERS="@im=fcitx"
fcitx &
# DE
exec ck-launch-session startkde
