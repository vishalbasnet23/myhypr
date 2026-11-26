#!/usr/bin/env python3
"""Generate dark.txt + light.txt for the extra nightwire flavours.

nightwire ships one flavour (neon). This adds sibling flavours in the same
cyberpunk family, each as a dark/light pair so caelestia's mode toggle keeps
working (modes = *.txt stems in the flavour dir).

Pipeline per flavour and mode:

1. Run materialyoucolor's DynamicScheme (VIBRANT) on the flavour's key
   colours to fill every M3 token, including the ones not hand-picked
   (fixed colours, inverse, dim/bright, lowest/highest containers).
2. Overwrite the hand-picked tokens in FLAVOURS below (surfaces, on-colours,
   primary/secondary/tertiary and their containers). These are the values
   previewed in the palette artifact and are the source of truth.
3. error/success, term*, named and k* colours are copied from neon
   (installed dark.txt for dark, repo light.txt for light) with term0/term8
   retinted to the flavour's own neutrals. Terminals are pinned by
   install.sh anyway, so these mostly matter for apps reading the scheme.
4. Deprecated extras (text/subtext/overlay/surface0-2/base/mantle/crust)
   mirror the tail of caelestia's gen_scheme(), as in gen-nightwire-light.py.

Usage:
    gen-nightwire-flavours.py [OUT_DIR]   # default: ./flavours next to this file
Writes OUT_DIR/<flavour>/{dark,light}.txt.
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

HERE = Path(__file__).resolve().parent
NEON_DARK = Path(
    "/usr/lib/python3.14/site-packages/caelestia/data/schemes/nightwire/neon/dark.txt"
)
NEON_LIGHT = HERE / "light.txt"

# Hand-picked tokens. Short keys:
#   bg  background/surface        sc   surfaceContainer   sch  surfaceContainerHigh
#   on  onSurface/onBackground    onv  onSurfaceVariant   ov   outlineVariant
#   p/onp/pc/onpc   primary, onPrimary, primaryContainer, onPrimaryContainer
#   s/onsc/sc2      secondary, onSecondaryContainer, secondaryContainer
#   t/tc/ontc       tertiary, tertiaryContainer, onTertiaryContainer
FLAVOURS = {
    "synthwave": {
        "dark": dict(bg="0e0a1a", sc="1a1430", sch="231b3d", on="efe7ff", onv="cbbfe6", ov="3f3460",
                     p="c86bff", onp="2c0050", pc="5a1a8c", onpc="f0d9ff",
                     s="ff9e4a", sc2="6b3200", onsc="ffdcc2",
                     t="3dd9ff", tc="004c5e", ontc="b8f0ff"),
        "light": dict(bg="fdf7ff", sc="f3ebff", sch="ece2fb", on="1f1530", onv="4d4163", ov="cfc2e6",
                      p="7c2fc0", onp="ffffff", pc="efdbff", onpc="5c1696",
                      s="9a4a00", sc2="ffdcc2", onsc="733500",
                      t="00677f", tc="b8f0ff", ontc="004d5f"),
    },
    "acid": {
        "dark": dict(bg="070d0a", sc="101a15", sch="16231c", on="e2f5ea", onv="b8d1c3", ov="2c4136",
                     p="39ff88", onp="00391b", pc="005229", onpc="a6ffc6",
                     s="ff4fb0", sc2="6e0047", onsc="ffd6eb",
                     t="ffb020", tc="5c3d00", ontc="ffe0a8"),
        "light": dict(bg="f6fcf8", sc="ebf5ef", sch="e3efe8", on="112019", onv="3e5247", ov="bdd3c6",
                      p="006d39", onp="ffffff", pc="9ff7bf", onpc="00522a",
                      s="b0006e", sc2="ffd8ea", onsc="8b0055",
                      t="7a5000", tc="ffdea0", ontc="5c3c00"),
    },
    "glacier": {
        "dark": dict(bg="080c15", sc="111827", sch="172033", on="e3ecff", onv="bcc8e0", ov="2c3a55",
                     p="7cc8ff", onp="00325a", pc="004a80", onpc="cfe6ff",
                     s="b59cff", sc2="432d8a", onsc="e8deff",
                     t="2dffd1", tc="005244", ontc="a8ffe9"),
        "light": dict(bg="f7faff", sc="ecf2fc", sch="e4ebf7", on="121c2d", onv="404b60", ov="c1cbdd",
                      p="00629c", onp="ffffff", pc="cfe6ff", onpc="004a77",
                      s="6146b8", sc2="e8deff", onsc="49309c",
                      t="006b58", tc="a8f5e0", ontc="005143"),
    },
    "redline": {
        "dark": dict(bg="110a0c", sc="1d1216", sch="27181d", on="f8e6ea", onv="dcc0c6", ov="4a2e35",
                     p="ff4060", onp="400012", pc="7a0021", onpc="ffd9de",
                     s="ffb020", sc2="5c3d00", onsc="ffe0a8",
                     t="00d8e6", tc="004f55", ontc="b0f5fa"),
        "light": dict(bg="fff8f7", sc="fbedee", sch="f5e4e6", on="2a1418", onv="5a4045", ov="e0c3c8",
                      p="b4002f", onp="ffffff", pc="ffdadd", onpc="8c0022",
                      s="855300", sc2="ffdea0", onsc="653f00",
                      t="006a72", tc="a6eef5", ontc="004f55"),
    },
    "amber": {
        "dark": dict(bg="0f0b05", sc="1c150a", sch="261c0e", on="fff0d6", onv="e0cba6", ov="4a3a1f",
                     p="ffb000", onp="3d2a00", pc="5c4000", onpc="ffdea0",
                     s="ff7a1a", sc2="6b2e00", onsc="ffdbc8",
                     t="7dd3a8", tc="00513a", ontc="b5f2d4"),
        "light": dict(bg="fffaf2", sc="f8efe0", sch="f2e7d4", on="241a08", onv="54452c", ov="dccbae",
                      p="7a5300", onp="ffffff", pc="ffdea0", onpc="5c3e00",
                      s="a34000", sc2="ffdbc8", onsc="7c2f00",
                      t="006c4f", tc="b5f2d4", ontc="00513a"),
    },
    "deepsea": {
        "dark": dict(bg="05100f", sc="0c1c1b", sch="122826", on="dff7f3", onv="b4d4cf", ov="254340",
                     p="00d1b2", onp="00382f", pc="005045", onpc="9ff5e3",
                     s="4d9bff", sc2="00427f", onsc="d3e4ff",
                     t="ffd166", tc="5a4300", ontc="ffe3a3"),
        "light": dict(bg="f4fcfa", sc="e8f5f2", sch="dff0ec", on="0f1f1d", onv="3c5450", ov="b9d3ce",
                      p="006b5c", onp="ffffff", pc="9ff5e3", onpc="005045",
                      s="0060ad", sc2="d3e4ff", onsc="004784",
                      t="765b00", tc="ffe3a3", ontc="5a4300"),
    },
    "moss": {
        "dark": dict(bg="0a0e07", sc="141b0f", sch="1c2515", on="eaf3dc", onv="c5d1b2", ov="37452a",
                     p="b5e655", onp="253600", pc="384f00", onpc="d6f7a0",
                     s="2dd4bf", sc2="004f46", onsc="a8f3e6",
                     t="ffb454", tc="5e3a00", ontc="ffddb5"),
        "light": dict(bg="f9fcf3", sc="eff4e6", sch="e8eedd", on="181f10", onv="444d38", ov="c6d1b5",
                      p="4a6700", onp="ffffff", pc="cdf08a", onpc="374e00",
                      s="006b5f", sc2="a8f3e6", onsc="005047",
                      t="845400", tc="ffddb5", ontc="643f00"),
    },
    "cobalt": {
        "dark": dict(bg="070a18", sc="10152b", sch="171d38", on="e3e8ff", onv="bec5e6", ov="2d3560",
                     p="5b8cff", onp="00296e", pc="0d3fa0", onpc="dae2ff",
                     s="00e5ff", sc2="004e5c", onsc="b3f3ff",
                     t="ffd23f", tc="594700", ontc="ffe58f"),
        "light": dict(bg="f8f9ff", sc="edf0ff", sch="e5e9fb", on="141a33", onv="434a68", ov="c3c9e8",
                      p="1f55d6", onp="ffffff", pc="dae2ff", onpc="0a3fa8",
                      s="006875", sc2="9cf0ff", onsc="004f58",
                      t="6d5a00", tc="ffe58f", ontc="524300"),
    },
    "chrome": {
        "dark": dict(bg="0b0c0e", sc="15171a", sch="1d2024", on="eceef1", onv="c3c7cd", ov="363a40",
                     p="d8dee6", onp="24292f", pc="3c434c", onpc="eef2f7",
                     s="00e5ff", sc2="004e5c", onsc="b3f3ff",
                     t="ffb020", tc="5c3d00", ontc="ffe0a8"),
        "light": dict(bg="fafbfc", sc="eff1f3", sch="e8eaed", on="1a1c1f", onv="464a50", ov="c8ccd2",
                      p="3a4350", onp="ffffff", pc="dde2e8", onpc="2a313a",
                      s="006875", sc2="9cf0ff", onsc="004f58",
                      t="7a5000", tc="ffdea0", ontc="5c3c00"),
    },
}

# Picked short key -> scheme token(s) it sets.
PICKED = {
    "bg": ["background", "surface", "base"],
    "sc": ["surfaceContainer"],
    "sch": ["surfaceContainerHigh"],
    "on": ["onBackground", "onSurface"],
    "onv": ["onSurfaceVariant"],
    "ov": ["outlineVariant"],
    "p": ["primary", "surfaceTint"],
    "onp": ["onPrimary"],
    "pc": ["primaryContainer"],
    "onpc": ["onPrimaryContainer"],
    "s": ["secondary"],
    "sc2": ["secondaryContainer"],
    "onsc": ["onSecondaryContainer"],
    "t": ["tertiary"],
    "tc": ["tertiaryContainer"],
    "ontc": ["onTertiaryContainer"],
}

# Copied verbatim from neon (same mode): semantic + terminal + named colours.
FROM_NEON_PREFIXES = ("term", "k")
FROM_NEON = {
    "error", "onError", "errorContainer", "onErrorContainer",
    "success", "onSuccess", "successContainer", "onSuccessContainer",
    "rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
    "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender",
}


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


def rgb_mix(a: str, b: str, t: float) -> str:
    """Linear sRGB blend, a -> b by t."""
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]
    cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    return "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ca, cb))


def palette(hexv: str) -> TonalPalette:
    return TonalPalette.from_int(int(f"0xFF{hexv}", 16))


def neutral_key(bg: str, chroma: float) -> str:
    """Neutral palette key colour carrying the flavour background's hue."""
    h = hex_to_hct(bg)
    return to_hex(Hct.from_hct(h.hue, chroma, 40))


def build(flavour: dict, mode: str, keys: dict, neon: dict, order: list[str]) -> dict[str, str]:
    is_dark = mode == "dark"
    pick = flavour[mode]
    nkey = neutral_key(pick["bg"], 10)
    nvkey = neutral_key(pick["bg"], 16)

    scheme = DynamicScheme(
        source_color_hct=hex_to_hct(keys["p"]),
        variant=Variant.VIBRANT,
        contrast_level=0.0,
        is_dark=is_dark,
        primary_palette=palette(keys["p"]),
        secondary_palette=palette(keys["s"]),
        tertiary_palette=palette(keys["t"]),
        neutral_palette=palette(nkey),
        neutral_variant_palette=palette(nvkey),
        error_palette=palette(neon["error"]),
    )
    mdc = {norm(c.name): c.get_hct(scheme) for c in MaterialDynamicColors().all_colors}

    out: dict[str, str] = {}
    for key in order:
        if norm(key) in mdc:
            out[key] = to_hex(mdc[norm(key)])

    out["primary_paletteKeyColor"] = keys["p"]
    out["secondary_paletteKeyColor"] = keys["s"]
    out["tertiary_paletteKeyColor"] = keys["t"]
    out["neutral_paletteKeyColor"] = nkey
    out["neutral_variant_paletteKeyColor"] = nvkey

    for short, tokens in PICKED.items():
        for token in tokens:
            out[token] = pick[short]

    # The generated surface ladder uses M3 tones, which don't line up with the
    # hand-picked bg/sc/sch (dark bg sits below M3's surface tone), so the
    # remaining rungs are interpolated from the picks to keep them ordered.
    bg, sc, sch, on = pick["bg"], pick["sc"], pick["sch"], pick["on"]
    shade = "000000" if is_dark else on
    out["surfaceContainerLowest"] = rgb_mix(bg, shade, 0.45) if is_dark else "ffffff"
    out["surfaceDim"] = rgb_mix(bg, shade, 0.3 if is_dark else 0.1)
    out["surfaceContainerLow"] = rgb_mix(bg, sc, 0.5)
    out["surfaceContainerHighest"] = rgb_mix(sch, on, 0.05)
    out["surfaceVariant"] = rgb_mix(sch, on, 0.07)
    out["surfaceBright"] = rgb_mix(sch, on, 0.04) if is_dark else bg

    for key in order:
        if key in FROM_NEON or key.startswith(FROM_NEON_PREFIXES):
            out[key] = neon[key]
    # Terminal background / bright-black follow the flavour's own neutrals.
    out["term0"] = pick["sc"] if is_dark else out["inverseOnSurface"]
    out["term8"] = pick["ov"] if is_dark else out["outline"]

    # Deprecated extras: mirror caelestia gen_scheme() tail.
    surface, outline = hex_to_hct(out["surface"]), hex_to_hct(out["outline"])
    out["text"] = out["onBackground"]
    out["subtext1"] = out["onSurfaceVariant"]
    out["subtext0"] = out["outline"]
    out["overlay2"] = to_hex(mix(surface, outline, 0.86))
    out["overlay1"] = to_hex(mix(surface, outline, 0.71))
    out["overlay0"] = to_hex(mix(surface, outline, 0.57))
    out["surface2"] = to_hex(mix(surface, outline, 0.43))
    out["surface1"] = to_hex(mix(surface, outline, 0.29))
    out["surface0"] = to_hex(mix(surface, outline, 0.14))
    out["mantle"] = to_hex(darken(surface, 0.03))
    out["crust"] = to_hex(darken(surface, 0.05))

    missing = [k for k in order if k not in out]
    if missing:
        raise SystemExit(f"{mode}: tokens not produced: {missing}")
    return out


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "flavours"
    neon = {"dark": parse_txt(NEON_DARK)[0], "light": parse_txt(NEON_LIGHT)[0]}
    _, order = parse_txt(NEON_DARK)

    for name, flavour in FLAVOURS.items():
        # Key colours (palette hues) always come from the dark picks: they are
        # the saturated neon versions, which is what M3 palettes expect.
        keys = flavour["dark"]
        for mode in ("dark", "light"):
            colours = build(flavour, mode, keys, neon[mode], order)
            path = out_dir / name / f"{mode}.txt"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("".join(f"{k} {colours[k]}\n" for k in order))
            print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
