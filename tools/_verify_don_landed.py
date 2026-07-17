from pathlib import Path

bis = Path(r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\lazbis\bis.lua").read_text(encoding="utf-8")
assert "id='don'" in bis
assert "['don'] = {" in bis
ini = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\lua\Turbo\rulepacks\BiS_announce_list.ini"
).read_text(encoding="utf-8")
assert ";DoN" in ini
assert "Mnemonic Glyph: Allegiance=ANNOUNCE" in ini
assert "Cryptic Clutch of Physical Prowess=ANNOUNCE" in ini
bc = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\lua\turbogear\bis_catalog.lua"
).read_text(encoding="utf-8")
assert 'id = "don"' in bc
print("verify_ok")
