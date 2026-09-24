#!/usr/bin/env python3
"""Draw the Instant Frame app icon and fill every AppIcon.appiconset slot.

Drawn in code (no image generation) at 4x and downsampled, on Apple's macOS
icon grid: an 824 px squircle body (superellipse, n = 5) centred on a
1024 px canvas, a soft drop shadow, transparent corners. Inside sits one
slightly tilted instant print: cream frame with the thick bottom border and a
sun-over-mountains photo, in the palette sampled from the previous icon.

Usage: python3 AppStore/generate_app_icon.py [--master out.png]
Needs Pillow and NumPy.
"""
import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4                      # supersampling factor
CANVAS = 1024
BODY = 824                  # Apple macOS grid: 824 px body on 1024
N = 5.0                     # superellipse exponent

# Palette sampled from the previous icon (most common opaque colours).
MAROON = (141, 45, 42)
CREAM = (255, 248, 234)
SKY = (107, 164, 184)
NAVY = (42, 69, 90)
SUN = (247, 195, 93)

ICONSET = Path(__file__).resolve().parent.parent / "Polaroid/Resources/Assets.xcassets/AppIcon.appiconset"


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(w, h, top, bottom):
    t = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None, None]
    top = np.array(top, np.float32)[None, None, :]
    bottom = np.array(bottom, np.float32)[None, None, :]
    rgb = top + (bottom - top) * t
    rgb = np.repeat(rgb, w, axis=1)
    alpha = np.full((h, w, 1), 255, np.float32)
    return Image.fromarray(np.concatenate([rgb, alpha], axis=2).round().astype(np.uint8), "RGBA")


def squircle_mask(size, body):
    """Anti-aliased superellipse mask, `body` px wide, centred in `size`."""
    c = (size - 1) / 2.0
    a = body / 2.0
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32)
    v = np.abs((xs - c) / a) ** N + np.abs((ys - c) / a) ** N
    return Image.fromarray(((v <= 1.0) * 255).astype(np.uint8), "L")


def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def draw_print(scale):
    """The instant print, upright, on a transparent layer. Returns (image, alpha)."""
    s = scale
    w, h = 500 * s, 596 * s            # overall print
    side, top = 32 * s, 32 * s          # thin borders
    photo = w - 2 * side                # square photo window
    bottom = h - top - photo            # the thick bottom border (~128 px)
    assert bottom > 3 * side

    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # Cream frame with a whisper of shading so it reads as paper, not a sticker.
    frame = vertical_gradient(w, h, mix(CREAM, (255, 255, 255), 0.35), mix(CREAM, (226, 214, 196), 0.35))
    frame_mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(frame_mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=14 * s, fill=255)
    layer.paste(frame, (0, 0), frame_mask)

    # Photo: sky, sun, two mountain ranges.
    px0, py0 = side, top
    scene = vertical_gradient(photo, photo, mix(SKY, NAVY, 0.10), mix(SKY, (255, 255, 255), 0.30))
    sd = ImageDraw.Draw(scene)
    p = photo
    # Sun, upper left, partly behind the far range.
    r = 0.13 * p
    cx, cy = 0.30 * p, 0.34 * p
    sd.ellipse((cx - r, cy - r, cx + r, cy + r), fill=SUN + (255,))
    # Far range: lighter, so there is depth without extra detail.
    far = mix(NAVY, SKY, 0.45)
    sd.polygon([(0, 0.78 * p), (0.40 * p, 0.46 * p), (0.62 * p, 0.62 * p),
                (0.80 * p, 0.50 * p), (p, 0.64 * p), (p, p), (0, p)], fill=far + (255,))
    # Near range: the navy from the old icon.
    sd.polygon([(0, 0.92 * p), (0.26 * p, 0.60 * p), (0.46 * p, 0.80 * p),
                (0.70 * p, 0.52 * p), (p, 0.88 * p), (p, p), (0, p)], fill=NAVY + (255,))

    photo_mask = Image.new("L", (p, p), 0)
    ImageDraw.Draw(photo_mask).rounded_rectangle((0, 0, p - 1, p - 1), radius=4 * s, fill=255)
    layer.paste(scene, (px0, py0), photo_mask)

    # A faint inner edge where the photo meets the frame.
    edge = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle((px0, py0, px0 + p - 1, py0 + p - 1),
                                           radius=4 * s, outline=(0, 0, 0, 40), width=2 * s)
    layer = Image.alpha_composite(layer, edge)
    return layer


def render_master():
    size = CANVAS * SS
    body = BODY * SS
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    mask = squircle_mask(size, body)

    # Soft drop shadow under the body (Apple grid: small y offset, wide blur).
    shadow_alpha = mask.filter(ImageFilter.GaussianBlur(14 * SS)).point(lambda v: round(v * 0.38))
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow.putalpha(Image.new("L", (size, size), 0))
    shadow.paste(Image.new("RGBA", (size, size), (0, 0, 0, 255)), (0, 10 * SS), shadow_alpha)
    canvas = Image.alpha_composite(canvas, shadow)

    # Body: maroon, lit from the top.
    fill = vertical_gradient(size, size, mix(MAROON, (214, 96, 84), 0.30), mix(MAROON, (60, 14, 16), 0.30))
    body_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    body_layer.paste(fill, (0, 0), mask)
    canvas = Image.alpha_composite(canvas, body_layer)

    # The print, tilted a few degrees, with its own soft shadow on the body.
    angle = 8.0  # counter-clockwise
    upright = draw_print(SS)
    tilted = upright.rotate(angle, resample=Image.BICUBIC, expand=True)
    tx = (size - tilted.width) // 2
    ty = (size - tilted.height) // 2 - 4 * SS

    print_alpha = Image.new("L", (size, size), 0)
    print_alpha.paste(tilted.getchannel("A"), (tx, ty))
    ps = print_alpha.filter(ImageFilter.GaussianBlur(12 * SS)).point(lambda v: round(v * 0.45))
    ps_shifted = Image.new("L", (size, size), 0)
    ps_shifted.paste(ps, (4 * SS, 14 * SS))
    # Keep the print's shadow on the body only.
    ps_shifted = Image.fromarray(np.minimum(np.array(ps_shifted), np.array(mask)), "L")
    print_shadow = Image.new("RGBA", (size, size), (40, 8, 8, 0))
    print_shadow.putalpha(ps_shifted)
    canvas = Image.alpha_composite(canvas, print_shadow)

    print_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    print_layer.paste(tilted, (tx, ty), tilted)
    canvas = Image.alpha_composite(canvas, print_layer)

    return canvas.resize((CANVAS, CANVAS), Image.LANCZOS)


def export_slots(master):
    contents = json.loads((ICONSET / "Contents.json").read_text())
    written = []
    for image in contents["images"]:
        points = int(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = points * scale
        out = master if px == CANVAS else master.resize((px, px), Image.LANCZOS)
        out.save(ICONSET / image["filename"], optimize=True)
        written.append((image["filename"], px))
    return written


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--master", help="also save the 1024 master here")
    args = ap.parse_args()
    master = render_master()
    if args.master:
        master.save(args.master)
    for name, px in export_slots(master):
        print(f"{name}: {px}x{px}")


if __name__ == "__main__":
    main()
