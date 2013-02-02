[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# keep clipboard in sync
autocutsel -selection CLIPBOARD -fork
autocutsel -selection PRIMARY -fork

# IM
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export EDITOR="xterm -e vim"
fcitx
exec i3
