import re
from pathlib import Path

text = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\tools\don_bis_block.lua"
).read_text(encoding="utf-8")
for cls in ["Shadow Knight", "Ranger", "Beastlord", "Enchanter", "Shaman", "Necromancer"]:
    m = re.search(rf"\['{re.escape(cls)}'\] = \{{(.*?)\n\t\t\}},", text, re.S)
    block = m.group(1) if m else ""
    clicks = re.findall(r"\['(Clicky\d*)'\] = ([^\n]+)", block)
    packs = re.findall(r"\['(Pack\d+)'\]", block)
    glyphs = re.findall(r"\['(Glyph\d+)'\]", block)
    augs = re.findall(r"\['(Aug\d+)'\]", block)
    print(cls)
    for k, v in clicks:
        print(" ", k, v[:100])
    print("  packs", len(packs), "glyphs", len(glyphs), "augs", len(augs))
