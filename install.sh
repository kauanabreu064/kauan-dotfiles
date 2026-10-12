#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOME_FILES="$ROOT/home"
PACKAGES="$ROOT/packages"
ASSETS="$ROOT/assets"
FIREFOX="$ROOT/firefox"

BACKUP="$HOME/.dotfiles-backup-$(date +%Y-%m-%d_%H-%M-%S)"


info() {
    printf '\n\033[1;35m[INFO]\033[0m %s\n' "$1"
}


ok() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$1"
}


warn() {
    printf '\033[1;33m[AVISO]\033[0m %s\n' "$1"
}


# ============================================================
# ARCH
# ============================================================

if [ ! -f /etc/arch-release ]; then
    echo "Este instalador foi feito para Arch Linux."
    exit 1
fi


echo
echo "=============================================="
echo "        Kauan Arch / Hyprland Dotfiles"
echo "=============================================="
echo
echo "Este instalador irá:"
echo
echo " - instalar os pacotes necessários"
echo " - instalar pacotes AUR"
echo " - restaurar as configurações"
echo " - configurar Fish"
echo " - configurar Firefox"
echo " - configurar Spicetify"
echo " - habilitar serviços necessários"
echo
echo "Configurações existentes serão copiadas para:"
echo
echo " $BACKUP"
echo

read -r -p "Continuar? [s/N] " resposta

case "$resposta" in
    s|S|sim|SIM)
        ;;
    *)
        echo "Cancelado."
        exit 0
        ;;
esac


# ============================================================
# BASE
# ============================================================

info "Instalando dependências básicas"

sudo pacman -S \
    --needed \
    --noconfirm \
    git \
    base-devel \
    rsync \
    curl \
    jq


# ============================================================
# PACOTES OFICIAIS
# ============================================================

if [ -f "$PACKAGES/pacman.txt" ]; then

    info "Instalando pacotes oficiais"

    while IFS= read -r pkg; do

        [ -z "$pkg" ] && continue


        if sudo pacman -S \
            --needed \
            --noconfirm \
            "$pkg"
        then

            ok "$pkg"

        else

            warn "Não foi possível instalar: $pkg"

        fi

    done < "$PACKAGES/pacman.txt"

fi


# ============================================================
# YAY
# ============================================================

if ! command -v yay >/dev/null 2>&1; then

    info "Instalando yay"

    TMP="$(mktemp -d)"

    git clone \
        https://aur.archlinux.org/yay-bin.git \
        "$TMP/yay-bin"


    (
        cd "$TMP/yay-bin"

        makepkg \
            -si \
            --noconfirm
    )


    rm -rf "$TMP"

fi


# ============================================================
# AUR
# ============================================================

if [ -f "$PACKAGES/aur.txt" ]; then

    info "Instalando pacotes AUR"

    while IFS= read -r pkg; do

        [ -z "$pkg" ] && continue


        if yay -S \
            --needed \
            --noconfirm \
            "$pkg"
        then

            ok "$pkg"

        else

            warn "Não foi possível instalar AUR: $pkg"

        fi

    done < "$PACKAGES/aur.txt"

fi


# ============================================================
# BACKUP
# ============================================================

info "Criando backup das configurações atuais"

mkdir -p "$BACKUP"


# ============================================================
# DOTFILES
# ============================================================

if [ -d "$HOME_FILES" ]; then

    info "Instalando dotfiles"

    rsync \
        -a \
        --backup \
        --backup-dir="$BACKUP" \
        "$HOME_FILES/" \
        "$HOME/"

fi


# ============================================================
# SCRIPTS
# ============================================================

if [ -d "$HOME/.local/bin" ]; then

    find "$HOME/.local/bin" \
        -maxdepth 1 \
        -type f \
        -exec chmod +x {} \;

fi


# ============================================================
# MALIKETH / FASTFETCH
# ============================================================

if [ -f "$ASSETS/maliketh.png" ]; then

    mkdir -p "$HOME/Pictures/fastfetch"

    cp \
        "$ASSETS/maliketh.png" \
        "$HOME/Pictures/fastfetch/maliketh.png"

fi


# ============================================================
# FISH
# ============================================================

if command -v fish >/dev/null 2>&1; then

    info "Configurando Fish"

    FISH="$(command -v fish)"

    if [ "$SHELL" != "$FISH" ]; then

        if ! grep -qx "$FISH" /etc/shells; then
            echo "$FISH" |
                sudo tee -a /etc/shells >/dev/null
        fi

        chsh \
            -s "$FISH" \
            "$USER" || true

    fi

fi


# ============================================================
# FIREFOX
# ============================================================

if [ -d "$FIREFOX/chrome" ]; then

    info "Configurando Firefox"

    FIREFOX_PROFILE=""

    for root in \
        "$HOME/.config/mozilla/firefox" \
        "$HOME/.mozilla/firefox"
    do

        [ -d "$root" ] || continue


        FIREFOX_PROFILE="$(
            find "$root" \
                -maxdepth 1 \
                -type d \
                -name '*.default-release' \
                2>/dev/null |
            head -n1
        )"


        [ -n "$FIREFOX_PROFILE" ] && break

    done


    if [ -n "$FIREFOX_PROFILE" ]; then

        mkdir -p \
            "$FIREFOX_PROFILE/chrome"


        rsync \
            -a \
            "$FIREFOX/chrome/" \
            "$FIREFOX_PROFILE/chrome/"


        USER_JS="$FIREFOX_PROFILE/user.js"


        if ! grep -q \
            'toolkit.legacyUserProfileCustomizations.stylesheets' \
            "$USER_JS" \
            2>/dev/null
        then

            echo \
'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
                >> "$USER_JS"

        fi


        ok "Firefox configurado"

    else

        warn "Nenhum perfil do Firefox encontrado."
        warn "Abra o Firefox uma vez e execute o instalador novamente."

    fi

fi


# ============================================================
# SERVIÇOS
# ============================================================

info "Configurando serviços"

if systemctl list-unit-files \
    NetworkManager.service \
    >/dev/null 2>&1
then

    sudo systemctl enable \
        NetworkManager.service \
        >/dev/null 2>&1 || true

fi


if systemctl list-unit-files \
    bluetooth.service \
    >/dev/null 2>&1
then

    sudo systemctl enable \
        bluetooth.service \
        >/dev/null 2>&1 || true

fi


if systemctl list-unit-files \
    sddm.service \
    >/dev/null 2>&1
then

    sudo systemctl enable \
        sddm.service \
        >/dev/null 2>&1 || true

fi


# ============================================================
# SYSTEMD USER
# ============================================================

if [ -d "$HOME/.config/systemd/user" ]; then

    systemctl \
        --user \
        daemon-reload \
        2>/dev/null || true

fi


if [ -f "$HOME/.config/systemd/user/start-muted.service" ]; then

    systemctl \
        --user \
        enable \
        start-muted.service \
        >/dev/null 2>&1 || true

fi


# ============================================================
# SPICETIFY
# ============================================================

if command -v spicetify >/dev/null 2>&1; then

    info "Configurando Spicetify"


    if [ -d /opt/spotify ]; then

        sudo chmod a+wr \
            /opt/spotify \
            2>/dev/null || true

        sudo chmod a+wr \
            /opt/spotify/Apps \
            -R \
            2>/dev/null || true

    fi


    spicetify config \
        current_theme \
        kauan-clean \
        >/dev/null 2>&1 || true


    spicetify config \
        color_scheme \
        Base \
        >/dev/null 2>&1 || true


    spicetify config \
        inject_css \
        1 \
        >/dev/null 2>&1 || true


    spicetify config \
        replace_colors \
        1 \
        >/dev/null 2>&1 || true


    spicetify config \
        overwrite_assets \
        1 \
        >/dev/null 2>&1 || true


    spicetify config \
        extensions \
        kauan-player.js \
        >/dev/null 2>&1 || true


    spicetify backup apply \
        >/dev/null 2>&1 || \
    spicetify apply \
        >/dev/null 2>&1 || true

fi


# ============================================================
# FINAL
# ============================================================

echo
echo "=============================================="
echo "             Instalação concluída"
echo "=============================================="
echo
echo "Backup das configurações antigas:"
echo
echo "  $BACKUP"
echo
echo "Faça logout e login novamente."
echo
echo "Se o Firefox era novo, abra-o uma vez e"
echo "execute ./install.sh novamente."
echo
