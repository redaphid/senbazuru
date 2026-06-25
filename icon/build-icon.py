#!/usr/bin/env python3
"""Build AppIcon.icns from the Paper Cranes crane, shaped to Apple's icon grid.

Usage: build-icon.py <source.png> <out.icns> <workdir>

Places the crane in an 824x824 squircle centered in a 1024 canvas (Apple's
macOS icon content box, 100px margins), then emits every iconset size and
runs iconutil. Squircle = superellipse (n=5), matching the system shape so
macOS icon masking is idempotent.
"""
import os
import subprocess
import sys

from PIL import Image, ImageChops

CANVAS = 1024
CONTENT = 824
MARGIN = (CANVAS - CONTENT) // 2
SS = 4  # supersample for smooth squircle edges


def squircle_mask(size: int) -> Image.Image:
    big = size * SS
    try:
        import numpy as np

        axis = np.linspace(-1.0, 1.0, big)
        x, y = np.meshgrid(axis, axis)
        inside = (np.abs(x) ** 5 + np.abs(y) ** 5) <= 1.0
        mask = Image.fromarray((inside * 255).astype("uint8"))
    except Exception:
        from PIL import ImageDraw

        mask = Image.new("L", (big, big), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, big - 1, big - 1], radius=int(0.2237 * big), fill=255
        )
    return mask.resize((size, size), Image.LANCZOS)


def main() -> None:
    src, out_icns, workdir = sys.argv[1], sys.argv[2], sys.argv[3]
    crane = Image.open(src).convert("RGBA").resize((CONTENT, CONTENT), Image.LANCZOS)

    r, g, b, a = crane.split()
    crane.putalpha(ImageChops.multiply(a, squircle_mask(CONTENT)))

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(crane, (MARGIN, MARGIN), crane)
    canvas.save(os.path.join(workdir, "master-1024.png"))

    iconset = os.path.join(workdir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    sizes = [
        (16, "16x16"), (32, "16x16@2x"),
        (32, "32x32"), (64, "32x32@2x"),
        (128, "128x128"), (256, "128x128@2x"),
        (256, "256x256"), (512, "256x256@2x"),
        (512, "512x512"), (1024, "512x512@2x"),
    ]
    for px, name in sizes:
        canvas.resize((px, px), Image.LANCZOS).save(os.path.join(iconset, f"icon_{name}.png"))

    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", out_icns], check=True)
    print("wrote", out_icns)


main()
