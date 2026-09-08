# hyprdots — Hyprland (Lua) + Waybar + AI dictionary popups

My personal Hyprland setup: Lua config (`hyprland.lua`), Sumi-e retro Waybar,
and small `fish`/`bash` helpers for instant AI dictionary / Anki cards.

- `Alt+W` → selected text → floating Duck.ai translator popup (+ service bar)
- `Alt+A` → selected text → centered Duck.ai Anki-card popup (Persian)
- `mpv` + `t` → current subtitle → exact same popup as `Alt+W`
- Waybar: Jalali clock, CPU/RAM, BPB proxy toggle, battery, mpris, tray, workspaces
- Screenshots, clipboard history, Okular quick-search, Kitty theme included

No secrets in this repo. Your proxy config (`~/bpb.json`) is **never** committed —
only `bpb/bpb.json.example` with placeholders is public.

---

## 1. Requirements

Tested on CachyOS / Arch, Hyprland 0.56 (Lua config), Waybar 0.15, fish 4, Chromium 152.

```bash
sudo pacman -S --needed hyprland waybar kitty thunar rofi fish chromium jq \
  wl-clipboard cliphist hyprpaper grim slurp playerctl power-profiles-daemon \
  networkmanager blueman pavucontrol brightnessctl sing-box mpv btop wtype \
  libnotify python
```

Jalali clock needs `jdatetime` (optional — falls back to Gregorian):

```bash
python3 -m venv /tmp/jdatetime-venv && /tmp/jdatetime-venv/bin/pip install jdatetime
```

Fonts: `FantasqueSansM Nerd Font`, `Vazirmatn`, `JetBrains Mono` (or edit `waybar/style.css`).

## 2. Install

```bash
git clone <your-repo-url> hyprdots
cd hyprdots
./install.sh
hyprctl reload; pkill waybar; waybar &
```

What `install.sh` does:

- backs up existing files to `~/.config-backup-DATE/`
- copies `hypr/hyprland.lua` → `~/.config/hypr/`
- copies `waybar/*` → `~/.config/waybar/` (+ `chmod +x` scripts)
- copies `mpv/*` → `~/.config/mpv/`
- copies `kitty/*` → `~/.config/kitty/`
- installs the bundled wallpaper → `~/.config/hypr/wallpapers/`
- copies `scripts/*` → `~/scripts/` and `~/.local/bin/okular-google-search`
- creates `~/.config/hyprdots/prompts/*.txt` from `prompts/*.txt.example` (AI prompt overrides — edit freely, never overwritten)
- installs `systemd/bpb.service` → `~/.config/systemd/user/` (needs your own `~/bpb.json`)
- `./install.sh --link` symlinks instead, `--dry-run` previews.

Set your wallpaper path in `~/.config/hypr/hyprpaper.conf`. The bundled Sumi-e
wallpaper (`metropolis.jpg`) is installed to `~/.config/hypr/wallpapers/` by
`install.sh`, so a fresh setup looks right out of the box:

```
path = ~/.config/hypr/wallpapers/metropolis.jpg
```

Proxy (optional): copy and fill your own servers — never commit the real one:

```bash
cp bpb/bpb.json.example ~/bpb.json
# edit ~/bpb.json, then:
systemctl --user enable --now bpb
```

## 3. Keybinds (from `hypr/hyprland.lua`, `mainMod = SUPER`)

| Bind | Action |
|---|---|
| `SUPER+Q` / `Z` / `T` / `E` | kitty / brave / Telegram / thunar |
| `SUPER+C` | close window |
| `SUPER+V` | toggle float |
| `SUPER+R` | rofi drun |
| `SUPER+F`, `SUPER+ALT+F` | toggle fullscreen |
| `SUPER+L` | toggle `dwindle` ⇄ `scrolling` layout |
| `SUPER+arrows` | move focus |
| `SUPER+SHIFT+arrows` | swap column (scrolling layout) |
| `SUPER+1..0` / `SUPER+SHIFT+1..0` | workspace / move to workspace |
| `SUPER+S` / `SUPER+SHIFT+S` | special scratchpad `magic` |
| `SUPER+TAB` / `SUPER+SHIFT+TAB` | next / previous workspace |
| `SUPER+SPACE` | switch keyboard `us ⇄ ir` |
| `SUPER+ESC` | `kitty -e btop` |
| `Print` | full screenshot → clipboard + `~/Pictures/Screenshots/` |
| `SHIFT+Print` | region screenshot (`grim` + `slurp`) |
| `ALT+V` | clipboard history (`cliphist` + `rofi`) |
| **`ALT+W`** | **dictionary popup (Duck.ai by default)** |
| **`ALT+A`** | **Anki-card popup (centered, no service bar)** |
| `SUPER+SHIFT+T` | Okular/Google quick-search (see §6) |
| `SUPER+SHIFT+Z` | hiddify |
| `CTRL+ALT+P` | gperiodic |
| `SUPER+B` | toggle waybar (`pkill -USR1 waybar`) |
| media keys | `wpctl` volume, `brightnessctl`, `playerctl` |

## 4. Alt+W — dictionary popup

`hyprland.lua`:

```lua
hl.bind("ALT + W", hl.dsp.exec_cmd("~/.config/waybar/scripts/dict-search.fish"), { locked = true })
```

Flow (`waybar/scripts/dict-search.fish` → `dict-open.fish`):

1. reads selection via `wl-paste --primary` (fallback `wl-paste`), trims to 4000 chars.
2. empty selection = toggle (closes popups).
3. kills old `chromium-dict-*` windows, ensures local server `dict-server.py` (`127.0.0.1:7634`) is up.
4. opens content window (`chromium --app` + `dict-load.html` → Duck.ai URL with prompt) sized `460×520` at `453,144`, floating + pinned.
5. opens service bar (`dict-bar.html`) sized `460×34` at `453,104` with buttons **Duck.ai / Google / Cambridge**.
6. window rules in `hyprland.lua` (`dict-bar`, `dict-content`) keep them floating, pinned, border 1.

Bar buttons call `http://127.0.0.1:7634/{duck,google,cambridge}?w=...` → `dict-open.fish <service>` re-opens content in place. `google` mode auto-starts `sing-box` from `~/bpb.json` if needed (reads port from config, default `2080`).

### Prompt sent before the selected text (Alt+W, `dict-open.fish`)

> تو یک مترجم علمی دقیق و یک استاد آموزش زبان هستی. متن انگلیسی انتهای این پیام را به فارسی جواب بده، کاملا راست‌چین و منظم با این ترتیب: 1) ترجمه کامل: یک ترجمه دقیق، روان، علمی و خوب از کل متن. 2) کالوکیشن‌ها رو هم بنویس: مهم‌ترین هم‌نشینی‌های کلمه کلیدی با معنی فارسی و یک مثال کوتاه. 3) کاربرد در جمله: 2-3 جمله انگلیسی با ترجمه فارسی. 4) ریشه‌شناسی و آموزش زبانی خلاصه: ریشه، مترادف‌ها و متضادها. اگر متن به یک حوزه تخصصی (علمی یا فنی) مربوط است، یک توضیح تخصصی مختصر هم اضافه کن. خلاصه بگو. متن:

URL built as `https://duck.ai/?q=<urlencoded(PROMPT + WORD)>`.
Cambridge mode opens `https://dictionary.cambridge.org/dictionary/english/<word>`,
Google mode opens `https://www.google.com/search?q=<urlencoded(PROMPT + WORD)>` via proxy.

### Customizing the AI prompts

All three prompts (dictionary, Anki, Okular) are **generic by default** and can be
personalized locally without touching the repo — e.g. to add your own field of study:

```bash
mkdir -p ~/.config/hyprdots/prompts
cp prompts/dict-prompt.txt.example ~/.config/hyprdots/prompts/dict-prompt.txt
# edit the file — it overrides the built-in prompt
```

| File | Overrides |
|---|---|
| `~/.config/hyprdots/prompts/dict-prompt.txt` | Alt+W / mpv `t` dictionary prompt |
| `~/.config/hyprdots/prompts/anki-prompt.txt` | Alt+A Anki-card prompt |
| `~/.config/hyprdots/prompts/okular-prompt.txt` | `SUPER+SHIFT+T` Okular/Google prompt |

`install.sh` creates these files from the examples on first run and never
overwrites your edits. They are **gitignored** — your personal details stay private.

## 5. Alt+A — Anki card popup

```lua
hl.bind("ALT + A", hl.dsp.exec_cmd("~/.config/waybar/scripts/anki-search.fish"), { locked = true })
```

Same selection logic, but:

- closes dict windows too (so `Alt+W`/`Alt+A` never overlap),
- opens `anki-load.html` → Duck.ai with the Anki prompt,
- window `560×620`, **centered on focused monitor**, floating + pinned, no service bar.

### Prompt sent before the selected text (Alt+A, `anki-open.fish`)

> تو یک استاد دانشگاه و متخصص ساخت فلش‌کارت آنکی به زبان فارسی هستی. متن انتخاب‌شده در انتهای این پیام می‌آید (ممکن است انگلیسی یا فارسی باشد). فقط همین دو کار را به همین ترتیب انجام بده و هیچ کار دیگری نکن: 1) ترجمه: اول یک ترجمه دقیق، روان و علمی از کل متن به فارسی بنویس. 2) کارت آنکی: بعد بر اساس همان متن فقط یک کارت آنکی عالی به زبان فارسی بساز (یک سؤال کوتاه و دقیق + یک جواب کامل ولی خلاصه، مناسب حفظ کردن). اگر اصطلاحی واقعا قابل ترجمه به فارسی نیست آن را به انگلیسی نگه دار. برای اطمینان از درستی علمی حتما از جست‌وجوی وب استفاده کن و بهترین و دقیق‌ترین کارت ممکن را پیشنهاد بده. کل خروجی فارسی و کاملا راست‌چین و منظم باشد. متن:

Customize with `~/.config/hyprdots/prompts/anki-prompt.txt` (see above).

## 6. mpv subtitle → same popup as Alt+W

`mpv/scripts/minimal-subtools.lua` + `mpv/script-opts/minimal-subtools.conf`:

| Key | Action |
|---|---|
| `t` (default, `key_translate`) | send current `sub-text` → `mpv-sub-open.fish` (same Duck.ai popup + bar) |
| `r` | replay current subtitle, pause |
| `Ctrl+r` | loop current subtitle on/off (`ab-loop`) |
| `shift+left/right`, `ctrl+left/right` | prev/next subtitle, pause, re-anchor loop |

Handoff is via `/tmp/mpv-sub.txt` (no clipboard race) + `wl-copy`. Same prompt as Alt+W.

`mpv/mpv.conf` enables fuzzy external subs, `slang=en,eng,fa,per,persian`, `sub-codepage=utf-8:utf-16:cp1256`.

## 7. Waybar

`waybar/config.jsonc` (height 18, Sumi-e theme in `style.css`):

- left: `hyprland/workspaces`
- center: `custom/clock` (Jalali via `custom-clock.sh`), `custom/motto`, `tray`
- right: `custom/mpris`, `custom/sysmon`, `custom/bpb`, `network`, `bluetooth`, `hyprland/language`, `pulseaudio`, `custom/battery`

Scripts:

| Script | Interval / action |
|---|---|
| `custom-clock.sh` | 60s, `HH:MM + Jalali day`, tooltip EN+FA date |
| `sysmon.sh` | 3s, CPU/RAM `%` via `/proc/stat` |
| `bpb-toggle.sh` | 2s, `systemctl --user is-active bpb`, click toggles |
| `battery-status.sh` | 2s, icon by `%`/charging/performance, click toggles `powerprofilesctl` |
| `mpris-status.sh` | 2s, icon per player + truncated title, tooltip lists players |
| `mpris-click.sh` | single = play-pause, double (<300ms) = exclusive menu |
| `mpris-exclusive.sh` | rofi/wofi picker, pauses all but chosen |
| `mpris-control.sh` | helper for click variants |
| `toggle-language`, `update-language` | legacy helpers (now `hyprland/language` module is used) |
| `dict-icon.fish` | legacy tray icon helper |

## 8. Other helpers (`scripts/`)

- `screenshot-copy` — fullscreen `grim` → `wl-copy` + save.
- `screenshot-copy-selection` — `grim -g "$(slurp)"` region version.
- `paste-last-screenshot` — copy newest `~/Pictures/Screenshots/*.png` into active Thunar dir (or cwd).
- `okular-google-search` (`SUPER+SHIFT+T`) — PRIMARY selection (or Ctrl+C via `wtype`), then opens Brave Google search with this prompt:

> من میخوام زبان یاد بگیرم در ادامه یه متن یا کلمه انگلیسی میدم بهت تو به فارسی ترجمه کن نکات خلاصه رو هم بگو بدون هیچ مقدمه ای بریم رو اصل کار اگه متن به یک حوزه تخصصی (علمی یا فنی) مربوطه توضیح تخصصی مختصر هم بده بدون مقدمه برو رواصل کار که مطالب بیخود نبینم :

Customize with `~/.config/hyprdots/prompts/okular-prompt.txt` (see §4).

## 9. Repo layout

```
hypr/hyprland.lua            # main Hyprland Lua config (binds, rules, autostart)
hypr/hyprpaper.conf.example  # wallpaper config (bundled wallpaper below)
hypr/wallpapers/metropolis.jpg  # bundled Sumi-e wallpaper (4K, ~2.4MB)
waybar/config.jsonc
waybar/style.css
waybar/scripts/              # dict/anki/mpris/clock/sysmon/battery/bpb
mpv/mpv.conf
mpv/scripts/minimal-subtools.lua
mpv/script-opts/minimal-subtools.conf
mpv/input.conf               # stub — add your own
kitty/kitty.conf
kitty/comfortable_dark.conf  # black + neutral white theme
scripts/screenshot-* , paste-last-screenshot, okular-google-search
prompts/*.txt.example         # AI prompt templates (copy to ~/.config/hyprdots/prompts/)
systemd/bpb.service          # sing-box user service (%h/bpb.json)
bpb/bpb.json.example         # FILL WITH YOUR OWN SERVERS
install.sh
```

## 10. Privacy

- ✅ Published: configs, scripts, prompts above, theme, keybinds.
- ✅ AI prompts are generic — your field of study (if any) stays out of the repo;
  personalize locally via `~/.config/hyprdots/prompts/*.txt` (gitignored).
- ❌ Never published: `~/bpb.json` (UUIDs, domains, paths), `~/.ssh/`, `~/.git-credentials`, browser profiles in `~/.cache/chromium-*`, `~/Pictures/Screenshots/`.
- Before `git push`, the repo was scanned for proxy secrets and real server
  credentials — only `YOUR_SERVER` / `YOUR-UUID` placeholders remain
  (in `bpb/bpb.json.example`).

License: MIT — use freely.
