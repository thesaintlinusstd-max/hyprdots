#!/usr/bin/env bash
# hyprdots installer — copies this repo's configs into ~/.config
# Usage:
#   ./install.sh            # copy files (safe default, backs up old ones)
#   ./install.sh --link     # symlink instead (for developing this repo)
#   ./install.sh --dry-run  # show what would happen
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
MODE="copy"
DRY=""

for arg in "$@"; do
  case "$arg" in
    --link) MODE="link" ;;
    --dry-run) DRY="echo [dry-run]" ;;
    -h|--help)
      echo "Usage: ./install.sh [--link] [--dry-run]"
      exit 0 ;;
  esac
done

say() { echo "==> $*"; }
do_install() {
  local src="$1" dst="$2"
  if [[ "$MODE" == "link" ]]; then
    $DRY ln -sfn "$src" "$dst"
  else
    if [[ -d "$src" ]]; then
      $DRY mkdir -p "$dst"
      # copy directory *contents* so existing extra files survive
      $DRY cp -r "$src/." "$dst/"
    else
      $DRY mkdir -p "$(dirname "$dst")"
      $DRY cp "$src" "$dst"
    fi
  fi
}

# 1. backup anything we are about to overwrite
say "Repo: $REPO"
say "Backup dir: $BACKUP"
TARGETS=(
  "$HOME/.config/hypr/hyprland.lua"
  "$HOME/.config/waybar"
  "$HOME/.config/mpv/mpv.conf"
  "$HOME/.config/mpv/scripts/minimal-subtools.lua"
  "$HOME/.config/mpv/script-opts/minimal-subtools.conf"
  "$HOME/.config/kitty/kitty.conf"
  "$HOME/.config/kitty/comfortable_dark.conf"
)
if [[ -z "$DRY" ]]; then mkdir -p "$BACKUP"; fi
for t in "${TARGETS[@]}"; do
  if [[ -e "$t" ]]; then
    rel="${t#$HOME/.config/}"
    $DRY mkdir -p "$BACKUP/$(dirname "$rel")"
    $DRY cp -r "$t" "$BACKUP/$rel" && say "backed up $t"
  fi
done

# 2. install configs
do_install "$REPO/hypr/hyprland.lua"              "$HOME/.config/hypr/hyprland.lua"
do_install "$REPO/waybar/config.jsonc"            "$HOME/.config/waybar/config.jsonc"
do_install "$REPO/waybar/style.css"               "$HOME/.config/waybar/style.css"
do_install "$REPO/waybar/scripts"                 "$HOME/.config/waybar/scripts"
do_install "$REPO/mpv/mpv.conf"                   "$HOME/.config/mpv/mpv.conf"
do_install "$REPO/mpv/scripts/minimal-subtools.lua"     "$HOME/.config/mpv/scripts/minimal-subtools.lua"
do_install "$REPO/mpv/script-opts/minimal-subtools.conf" "$HOME/.config/mpv/script-opts/minimal-subtools.conf"
do_install "$REPO/kitty/kitty.conf"               "$HOME/.config/kitty/kitty.conf"
do_install "$REPO/kitty/comfortable_dark.conf"    "$HOME/.config/kitty/comfortable_dark.conf"

# helper scripts -> ~/scripts + ~/.local/bin (matches hyprland.lua binds)
do_install "$REPO/scripts/screenshot-copy"           "$HOME/scripts/screenshot-copy"
do_install "$REPO/scripts/screenshot-copy-selection" "$HOME/scripts/screenshot-copy-selection"
do_install "$REPO/scripts/paste-last-screenshot"     "$HOME/scripts/paste-last-screenshot"
do_install "$REPO/scripts/okular-google-search"      "$HOME/.local/bin/okular-google-search"

# AI prompt overrides (~/.config/hyprdots/prompts/ — edit these to personalize,
# they are gitignored and never overwritten once they exist)
if [[ -d "$REPO/prompts" ]]; then
  $DRY mkdir -p "$HOME/.config/hyprdots/prompts"
  for f in "$REPO/prompts/"*.txt.example; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f" .txt.example)"
    if [[ ! -e "$HOME/.config/hyprdots/prompts/$base.txt" ]]; then
      $DRY cp "$f" "$HOME/.config/hyprdots/prompts/$base.txt"
      say "created ~/.config/hyprdots/prompts/$base.txt (edit to personalize the AI prompt)"
    else
      say "kept existing ~/.config/hyprdots/prompts/$base.txt"
    fi
  done
fi

# bundled wallpaper (fresh installs get the same background immediately)
if [[ ! -e "$HOME/.config/hypr/wallpapers/metropolis.jpg" && -e "$REPO/hypr/wallpapers/metropolis.jpg" ]]; then
  do_install "$REPO/hypr/wallpapers" "$HOME/.config/hypr/wallpapers"
  say "installed bundled wallpaper -> ~/.config/hypr/wallpapers/metropolis.jpg"
fi

# hyprpaper example (won't overwrite your wallpaper setup blindly)
if [[ ! -e "$HOME/.config/hypr/hyprpaper.conf" ]]; then
  do_install "$REPO/hypr/hyprpaper.conf.example" "$HOME/.config/hypr/hyprpaper.conf"
  say "installed hyprpaper.conf (edit the wallpaper path inside)"
else
  say "kept existing ~/.config/hypr/hyprpaper.conf (see hypr/hyprpaper.conf.example)"
fi

# 3. permissions
$DRY chmod +x "$HOME/.config/waybar/scripts/"*.sh "$HOME/.config/waybar/scripts/"*.fish "$HOME/.config/waybar/scripts/"*.py 2>/dev/null || true
$DRY chmod +x "$HOME/scripts/screenshot-copy" "$HOME/scripts/screenshot-copy-selection" "$HOME/scripts/paste-last-screenshot" "$HOME/.local/bin/okular-google-search" 2>/dev/null || true

# 4. bpb proxy (optional, needs YOUR OWN servers — never committed)
if [[ ! -e "$HOME/bpb.json" && -e "$REPO/bpb/bpb.json.example" ]]; then
  $DRY cp "$REPO/bpb/bpb.json.example" "$HOME/bpb.json"
  say "created ~/bpb.json from example — EDIT IT with your own servers"
fi
if [[ -e "$REPO/systemd/bpb.service" ]]; then
  $DRY mkdir -p "$HOME/.config/systemd/user"
  do_install "$REPO/systemd/bpb.service" "$HOME/.config/systemd/user/bpb.service"
  if [[ -z "$DRY" ]] && command -v systemctl >/dev/null; then
    systemctl --user daemon-reload || true
    say "bpb.service installed. Enable with: systemctl --user enable --now bpb"
  fi
fi

# 5. dependency check (Arch/CachyOS names)
say "Checking dependencies..."
MISSING=()
for cmd in hyprland waybar kitty thunar rofi fish chromium jq wl-paste wl-copy cliphist hyprpaper grim slurp playerctl powerprofilesctl nmcli blueman-manager pavucontrol brightnessctl sing-box mpv btop wtype notify-send python3; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done
if ((${#MISSING[@]})); then
  say "Missing commands: ${MISSING[*]}"
  echo "    On Arch/CachyOS try:"
  echo "    sudo pacman -S --needed hyprland waybar kitty thunar rofi fish chromium jq wl-clipboard cliphist hyprpaper grim slurp playerctl power-profiles-daemon networkmanager blueman pavucontrol brightnessctl sing-box mpv btop wtype libnotify python"
  echo "    + python jdatetime for the Jalali clock:  python3 -m venv /tmp/jdatetime-venv && /tmp/jdatetime-venv/bin/pip install jdatetime"
else
  say "All core commands found."
fi

say "Done. Reload with: hyprctl reload; pkill waybar; waybar &"
say "Old configs backed up in: $BACKUP"
