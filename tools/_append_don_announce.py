from pathlib import Path

ini_path = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\lua\Turbo\rulepacks\BiS_announce_list.ini"
)
names_path = Path(
    r"D:\Desktop\Turbo v3.9.88\Turbo v3.9.88 git\Turbo v3.9.88\tools\don_announce_names.txt"
)
text = ini_path.read_text(encoding="utf-8")
if ";DoN" in text or text.rstrip().endswith("DoN"):
    # check for section
    pass
if "\n;DoN\n" in text or text.startswith(";DoN\n"):
    print("DoN section already present; skipping")
else:
    names = [n.strip() for n in names_path.read_text(encoding="utf-8").splitlines() if n.strip()]
    block = ["", ";DoN"] + [f"{n}=ANNOUNCE" for n in names] + [""]
    # Ensure file ends with newline before append
    if not text.endswith("\n"):
        text += "\n"
    text = text.rstrip("\n") + "\n" + "\n".join(block)
    ini_path.write_text(text, encoding="utf-8")
    print(f"Appended {len(names)} DoN announce names")
