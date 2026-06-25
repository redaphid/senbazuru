#!/usr/bin/env python3
"""Extract the Paper Cranes crane as a monochrome menu-bar template image.

Usage: build-menubar.py <source.png> <out.png>

Separates the warm crane from the blue background on the blue channel, then
renders a solid-black silhouette on transparent — a macOS "template" image the
status bar tints for light/dark. Padded to a square with a little breathing room.
"""
import sys

import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
a = np.asarray(im).astype(np.int16)
blue, existing = a[..., 2], a[..., 3]

# Tight band keeps the whole crane body opaque (a solid template silhouette),
# leaving only a thin antialiased edge where it meets the blue background.
lo, hi = 120, 150
alpha = np.clip((hi - blue) / (hi - lo) * 255, 0, 255)
alpha = np.where(existing > 0, alpha, 0).astype("uint8")

crane = Image.new("RGBA", im.size, (0, 0, 0, 0))
crane.putalpha(Image.fromarray(alpha))
crane = crane.crop(crane.getbbox())

side = int(max(crane.size) * 1.18)
canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
canvas.paste(crane, ((side - crane.width) // 2, (side - crane.height) // 2), crane)
canvas.resize((256, 256), Image.LANCZOS).save(out)
print("wrote", out)
