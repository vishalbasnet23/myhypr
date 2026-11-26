# nightwire light mode

caelestia's `nightwire/neon` scheme ships dark-only. `light.txt` adds a
light variant generated from nightwire's own key palettes (pink `ff2e9a` /
cyan `00e5ff` / lime `d4ff3d` on blue-tinted neutrals) via
`materialyoucolor` — the same library caelestia's scheme generator uses.
Standard Material 3 light tones; term/named/k colours are nightwire's own
hues tone-mapped for light backgrounds.

## Install

```sh
sudo cp light.txt /usr/lib/python3.14/site-packages/caelestia/data/schemes/nightwire/neon/light.txt
```

Then switch: `caelestia scheme set -m light` (or the dark-mode toggle in
Nexus settings → Wallpaper & style). Back to dark: `caelestia scheme set -m dark`.

## After a caelestia-shell package update

`pacman -Syu caelestia-shell` replaces the package's scheme data and drops
`light.txt` (same failure class as the `/etc/xdg/quickshell/caelestia`
symlink). Symptoms: `caelestia scheme set -m light` silently bounces back
to dark (`_check_mode` validates against `*.txt` stems in the flavour dir).
Fix: re-run the install command above.

## Extra flavours

`flavours/<name>/{dark,light}.txt` adds sibling flavours in the same
family: `synthwave`, `acid`, `glacier`, `redline`, `amber`, `deepsea`,
`moss`, `cobalt`, `chrome`. Each is a dark/light pair,
so the mode toggle works on all of them. They are picked from Nexus settings
→ Wallpaper & style → Colours (`caelestia/modules/nexus/pages/wallandstyle/ColourSelect.qml`),
or `caelestia scheme set -n nightwire -f <name>`.

The hand-picked tokens (surfaces, primary/secondary/tertiary and containers)
live in `FLAVOURS` in `gen-nightwire-flavours.py`; everything else is filled
from materialyoucolor and neon's own term/named colours. Edit the table,
then regenerate and reinstall:

```sh
python3 gen-nightwire-flavours.py     # rewrites flavours/*/{dark,light}.txt
sudo bash install.sh
```

`install.sh` copies them along with `light.txt`, and they get wiped by the
same `caelestia-shell` package update.

## Regenerate

`gen-nightwire-light.py` parses key colours out of the installed
`dark.txt`, so it picks up upstream tweaks to nightwire automatically.
Requires the `caelestia` Python package + `materialyoucolor` on the path
(both come with caelestia-shell).

```sh
python3 gen-nightwire-light.py > light.txt          # light palette
python3 gen-nightwire-light.py --dark               # self-test: token coverage
```
