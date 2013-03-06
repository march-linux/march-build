[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# IM
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export EDITOR="urxvt -e vim"
fcitx
mimi ~/memo.txt
feh --bg-scale ~/.wallpaper/wallpaper.jpg
exec i3
