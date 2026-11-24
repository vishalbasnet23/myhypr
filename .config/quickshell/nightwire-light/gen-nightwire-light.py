#!/usr/bin/env python3
"""Generate a light.txt for caelestia's nightwire/neon scheme.

nightwire ships dark-only (data/schemes/nightwire/neon/dark.txt), and its
dark palette is hand-tuned M3: primary ff2e9a / secondary 00e5ff /
tertiary d4ff3d on blue-tinted neutrals, with custom neon term colours.

This builds the light-mode counterpart using materialyoucolor (the same
library caelestia's own generator uses):

- Core M3 tokens (surfaces, containers, on-colours, fixed colours):
  standard light tones generated from nightwire's own key palettes via
  DynamicScheme(variant=VIBRANT, is_dark=False) -> MaterialDynamicColors.
- term*/named/k* colours: nightwire's own hues, tone-mapped for light
  backgrounds (terminal light conventions: term0 bright, term7/15 dark).
- success block: nightwire's neon green, tone-mapped the same way.
- Deprecated extras (text/subtext/overlay/surface0-2/base/mantle/crust):
  replicate the tail of caelestia's gen_scheme() exactly.

Key colours are parsed out of the installed dark.txt, so any future
upstream tweak to nightwire is picked up on regeneration.

Usage:
    gen-nightwire-light.py            # emit light palette to stdout
    gen-nightwire-light.py --dark     # self-test: emit dark palette from
                                      # the same pipeline; diff vs dark.txt
                                      # to verify token coverage
"""

import sys
from pathlib import Path

from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.dynamiccolor.variant import Variant
from materialyoucolor.hct import Hct
from materialyoucolor.palettes.tonal_palette import TonalPalette

try:
    from materialyoucolor.dynamiccolor.dynamic_scheme import DynamicScheme
except ImportError:
    from materialyoucolor.scheme.dynamic_scheme import DynamicScheme

from caelestia.utils.material.generator import darken, hex_to_hct, mix

DARK_TXT = Path(
    "/usr/lib/python3.14/site-packages/caelestia/data/schemes/nightwire/neon/dark.txt"
)

NAMED_COLOURS = [
    "rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
    "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender",
]
KCOLOURS = ["klink", "kvisited", "knegative", "kneutral", "kpositive"]

# Light-mode terminal conventions: term0 = bg slot (bright), term7 = fg slot
# (dark), term8 = bright-black (mid grey), term15 = bright-white (dark).
TERM_TONES = {0: 95, 7: 15, 8: 45, 15: 20}
TERM_TONE_DEFAULT = 40


def parse_txt(path: Path) -> tuple[dict[str, str], list[str]]:
    colours, order = {}, []
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        key, value = line.split()
        colours[key] = value.removeprefix("#")
        order.append(key)
    return colours, order


def norm(key: str) -> str:
    return key.replace("_", "").lower()


def to_hex(hct: Hct) -> str:
    return f"{hct.to_int() & 0xFFFFFF:06x}"


def argb_to_hex(argb: int) -> str:
    """TonalPalette.tone() returns a raw ARGB int in materialyoucolor 3.x."""
    return f"{argb & 0xFFFFFF:06x}"


def remap(hexv: str, tone: float, chroma_scale: float = 1.0) -> str:
    """Keep hue (and scaled chroma) of hexv, force HCT tone."""
    h = hex_to_hct(hexv)
    return to_hex(Hct.from_hct(h.hue, h.chroma * chroma_scale, tone))


def palette(hexv: str) -> TonalPalette:
    return TonalPalette.from_int(int(f"0xFF{hexv}", 16))


def main() -> int:
    is_dark = "--dark" in sys.argv[1:]
    dark, order = parse_txt(DARK_TXT)

    scheme = DynamicScheme(
        source_color_hct=hex_to_hct(dark["primary_paletteKeyColor"]),
        variant=Variant.VIBRANT,
        contrast_level=0.0,
        is_dark=is_dark,
        primary_palette=palette(dark["primary_paletteKeyColor"]),
        secondary_palette=palette(dark["secondary_paletteKeyColor"]),
        tertiary_palette=palette(dark["tertiary_paletteKeyColor"]),
        neutral_palette=palette(dark["neutral_paletteKeyColor"]),
        neutral_variant_palette=palette(dark["neutral_variant_paletteKeyColor"]),
        error_palette=palette(dark["error"]),
    )

    mdc = {
        norm(c.name): c.get_hct(scheme) for c in MaterialDynamicColors().all_colors
    }

    out: dict[str, str] = {}
    for key in order:
        if norm(key) in mdc:
            out[key] = to_hex(mdc[norm(key)])

    missing = [k for k in order if k not in out]

    if is_dark:
        # Self-test: keep hand-tuned values for non-MDC groups so the diff
        # against dark.txt only shows the core M3 token pipeline.
        for key in order:
            out.setdefault(key, dark[key])
    else:
        for i in range(16):
            tone = TERM_TONES.get(i, TERM_TONE_DEFAULT)
            scale = 0.6 if i == 7 else 1.0
            out[f"term{i}"] = remap(dark[f"term{i}"], tone, scale)
        for name in NAMED_COLOURS:
            out[name] = remap(dark[name], 45)
        for name in KCOLOURS:
            out[name] = remap(dark[name], 40)
            out[f"{name}Selection"] = out[name]
        success = palette(dark["success"])
        out["success"] = argb_to_hex(success.tone(40))
        out["onSuccess"] = argb_to_hex(success.tone(100))
        out["successContainer"] = argb_to_hex(success.tone(90))
        out["onSuccessContainer"] = argb_to_hex(success.tone(30))

    # Deprecated extras — mirror caelestia gen_scheme() tail.
    surface, outline = mdc[norm("surface")], mdc[norm("outline")]
    out["text"] = out["onBackground"]
    out["subtext1"] = out["onSurfaceVariant"]
    out["subtext0"] = out["outline"]
    out["overlay2"] = to_hex(mix(surface, outline, 0.86))
    out["overlay1"] = to_hex(mix(surface, outline, 0.71))
    out["overlay0"] = to_hex(mix(surface, outline, 0.57))
    out["surface2"] = to_hex(mix(surface, outline, 0.43))
    out["surface1"] = to_hex(mix(surface, outline, 0.29))
    out["surface0"] = to_hex(mix(surface, outline, 0.14))
    out["base"] = out["surface"]
    out["mantle"] = to_hex(darken(surface, 0.03))
    out["crust"] = to_hex(darken(surface, 0.05))

    if missing:
        print(f"WARNING: tokens not covered by MaterialDynamicColors: {missing}",
              file=sys.stderr)

    for key in order:
        print(f"{key} {out[key]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
