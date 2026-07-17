from pathlib import Path
import re

bis = Path(r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\lazbis\bis.lua")
block = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\tools\don_bis_block.lua"
).read_text(encoding="utf-8")
text = bis.read_text(encoding="utf-8")

old = "\t\t\t[6]={id='veksar',name='Veksar'},"
new = (
    "\t\t\t[6]={id='veksar',name='Veksar'},\n"
    "\t\t\t[7]={id='don',name='DoN'},"
)
if "id='don'" not in text:
    if old not in text:
        raise SystemExit("ItemLists veksar not found")
    text = text.replace(old, new, 1)
    print("Added ItemLists don")
else:
    print("ItemLists don already present")

marker = "\t},\n\t['jonas'] = {"
if re.search(r"\n\t\['don'\] = \{", text):
    print("Replacing existing don block")
    text, n = re.subn(
        r"\n\t\['don'\] = \{.*?\n\t\},\n\t\['jonas'\]",
        "\n" + block.rstrip() + "\n\t['jonas']",
        text,
        count=1,
        flags=re.S,
    )
    if n != 1:
        raise SystemExit(f"don replace failed n={n}")
else:
    if marker not in text:
        raise SystemExit("jonas marker not found")
    text = text.replace(marker, "\t},\n" + block.rstrip() + "\n\t['jonas'] = {", 1)
    print("Inserted don block before jonas")

bis.write_text(text, encoding="utf-8")
print("Wrote", bis, "size", bis.stat().st_size)
