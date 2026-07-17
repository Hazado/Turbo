#!/usr/bin/env python3
"""Merge merchant 2089271 spell/tome rows into tools/don_bis_block.lua Pack slots."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BLOCK = ROOT / "tools" / "don_bis_block.lua"
ANNOUNCE_INI = ROOT / "lua" / "Turbo" / "rulepacks" / "BiS_announce_list.ini"
ANNOUNCE_NAMES = ROOT / "tools" / "don_announce_names.txt"

ABBREV_TO_CLASS = {
    "WAR": "Warrior",
    "CLR": "Cleric",
    "PAL": "Paladin",
    "RNG": "Ranger",
    "SHD": "Shadow Knight",
    "DRU": "Druid",
    "MNK": "Monk",
    "BRD": "Bard",
    "ROG": "Rogue",
    "SHM": "Shaman",
    "NEC": "Necromancer",
    "WIZ": "Wizard",
    "MAG": "Magician",
    "ENC": "Enchanter",
    "BST": "Beastlord",
    "BER": "Berserker",
}

# class_abbr, item_id, item_name — from merchant 2089271 usable-class dump
VENDOR_ROWS: list[tuple[str, int, str]] = [
    ("BER", 79226, "Tome of Arcane Reprisal"),
    ("BER", 59925, "Tome of Battle Focus Discipline"),
    ("BER", 79251, "Tome of Bloodcurdling Scream"),
    ("BER", 50120, "Tome of Cleaving Madness Discipline"),
    ("BER", 50118, "Tome of Cry of Catastrophe"),
    ("BER", 80081, "Tome of Fourth Wind"),
    ("BER", 80280, "Tome of Rancorous Flurry Discipline"),
    ("BER", 50119, "Tome of Vigorous Axe Throw"),
    ("BER", 80281, "Tome of Wounded Rage Discipline"),
    ("BRD", 81935, "Song: Niv's Symphonic"),
    ("BRD", 78739, "Song: One Bard Band"),
    ("BRD", 50157, "Song: Squall Blade"),
    ("BRD", 82821, "Spell Pack: Cantata of Nife"),
    ("BRD", 82823, "Spell Pack: Echoes of the Ancient"),
    ("BRD", 82822, "Spell Pack: Symphony of Sound"),
    ("BRD", 79226, "Tome of Arcane Reprisal"),
    ("BRD", 50156, "Tome of Endless Blades"),
    ("BST", 82819, "Spell Pack: Growl of the Mountain Puma"),
    ("BST", 82818, "Spell Pack: Roaring Spirit of Tirranun"),
    ("BST", 82820, "Spell Pack: Sha's Urgent Renewal"),
    ("BST", 82817, "Spell Pack: Spiritual Vibrance"),
    ("BST", 81933, "Spell: Feral Mettle"),
    ("BST", 81934, "Spell: Ravenous Ice"),
    ("BST", 78701, "Spell: Roaring Sleet"),
    ("BST", 81868, "Spell: Spiritual Enlightenment"),
    ("BST", 81867, "Spell: Swift Salve of the Stillmoon"),
    ("CLR", 82661, "Spell Pack: Aegis of Vie"),
    ("CLR", 82658, "Spell Pack: Allegiance"),
    ("CLR", 82660, "Spell Pack: Armor of the Sacred"),
    ("CLR", 80284, "Spell: Chromablast"),
    ("CLR", 124941, "Spell: Divine Redemption"),
    ("CLR", 78149, "Spell: Elixir of Redemption"),
    ("CLR", 78086, "Spell: Sound of Zeal"),
    ("CLR", 80282, "Spell: Urgent Renewal"),
    ("CLR", 80283, "Spell: Vigilant Censure"),
    ("DRU", 82777, "Spell Pack: Clumped Moss"),
    ("DRU", 82688, "Spell Pack: Spiritoaks"),
    ("DRU", 82778, "Spell Pack: Sun's Blistering Corona"),
    ("DRU", 80757, "Spell: Ascent Frost"),
    ("DRU", 78200, "Spell: Breath of the Ascent"),
    ("DRU", 80758, "Spell: Dawnflame"),
    ("DRU", 80759, "Spell: Lunar Shadow"),
    ("DRU", 117592, "Spell: Nature Seeker's Behest"),
    ("DRU", 80756, "Spell: Sunburst Devotion"),
    ("ENC", 82804, "Spell Pack: Edict of Tashan"),
    ("ENC", 82802, "Spell Pack: Ellowind Hastening"),
    ("ENC", 82801, "Spell Pack: Intuition"),
    ("ENC", 82803, "Spell Pack: Presidio of the Seer"),
    ("ENC", 50149, "Spell: Boon of the Sentinel"),
    ("ENC", 80781, "Spell: Chromatic Chaos"),
    ("ENC", 80783, "Spell: Hysteria"),
    ("ENC", 80782, "Spell: Urgent Rune of Destiny"),
    ("ENC", 80780, "Spell: Whispers of Emoush"),
    ("MAG", 82799, "Spell Pack: Circle of Magmaskin"),
    ("MAG", 82800, "Spell Pack: Goner's Urgent Renewal"),
    ("MAG", 82798, "Spell Pack: Ward of the Conjurer"),
    ("MAG", 80766, "Spell: Blade Rend"),
    ("MAG", 50144, "Spell: Burning Bladestorm"),
    ("MAG", 79091, "Spell: Fickle Inferno"),
    ("MAG", 80764, "Spell: Frantic Blaze"),
    ("MAG", 80779, "Spell: Grant Battle Materiel"),
    ("MAG", 80765, "Spell: Monolithic Strength"),
    ("MNK", 79226, "Tome of Arcane Reprisal"),
    ("MNK", 88921, "Tome of Dragondance Discipline"),
    ("MNK", 50117, "Tome of Fists of Thundercrest"),
    ("MNK", 80081, "Tome of Fourth Wind"),
    ("MNK", 80078, "Tome of Grandmaster's Aura"),
    ("MNK", 118654, "Tome of Phantom Whispers"),
    ("MNK", 79445, "Tome of Stormfist Discipline"),
    ("MNK", 80083, "Tome of Velocity Focus"),
    ("MNK", 88901, "Tome of Wheel of Fists"),
    ("NEC", 82806, "Spell Pack: Dull Agony"),
    ("NEC", 82800, "Spell Pack: Goner's Urgent Renewal"),
    ("NEC", 82805, "Spell Pack: Sacrilege of the Wraith"),
    ("NEC", 80786, "Spell: Malignant Plague"),
    ("NEC", 80785, "Spell: Molten Pyre"),
    ("NEC", 119599, "Spell: Pestilent Pustules"),
    ("NEC", 78819, "Spell: Ritual of Blood"),
    ("NEC", 78892, "Spell: Venom of the Accursed Nest"),
    ("NEC", 80784, "Spell: Yearning of Death"),
    ("PAL", 82810, "Spell Pack: Armor of the Savior"),
    ("PAL", 82811, "Spell Pack: Virtuous Fervor"),
    ("PAL", 82812, "Spell Pack: Wave of the Stillmoon"),
    ("PAL", 81864, "Spell: Benevolent Aura"),
    ("PAL", 81862, "Spell: Brell's Unshakable Barricade"),
    ("PAL", 81861, "Spell: Force of the Sacred"),
    ("PAL", 81863, "Spell: Force of the Sentinel"),
    ("PAL", 78039, "Spell: The Silent Decree"),
    ("PAL", 79399, "Tome of Aegis of Righteousness"),
    ("RNG", 82815, "Spell Pack: Call of Storms"),
    ("RNG", 50150, "Spell Pack: Flame and Frost"),
    ("RNG", 82814, "Spell Pack: Guard of Thundercrest"),
    ("RNG", 82813, "Spell Pack: Snarl of the Predator"),
    ("RNG", 81866, "Spell: Eyes of the Drake"),
    ("RNG", 116082, "Spell: Heartshatter"),
    ("RNG", 81867, "Spell: Swift Salve of the Stillmoon"),
    ("RNG", 81865, "Spell: Ward of the Stalker"),
    ("RNG", 82816, "Tome Pack: Jolting Thunderkicks"),
    ("ROG", 79226, "Tome of Arcane Reprisal"),
    ("ROG", 80087, "Tome of Assailant Discipline"),
    ("ROG", 80081, "Tome of Fourth Wind"),
    ("ROG", 80088, "Tome of Frenetic Stabbing Discipline"),
    ("ROG", 80085, "Tome of Lithe Discipline"),
    ("ROG", 88900, "Tome of Outlaw's Glare"),
    ("ROG", 88902, "Tome of Pinpoint Weakness"),
    ("ROG", 50116, "Tome of Twisted Fortune Discipline"),
    ("ROG", 79236, "Tome of Vigorous Dagger Throw"),
    ("SHD", 82807, "Spell Pack: Cloak of the Corrupter"),
    ("SHD", 82808, "Spell Pack: Shroud of the Accursed"),
    ("SHD", 82809, "Spell Pack: Theft of Misery"),
    ("SHD", 80788, "Spell: Blood of the Harbinger"),
    ("SHD", 78565, "Spell: Grasp of Ju'rek"),
    ("SHD", 78594, "Spell: Terror of Lavaspinner's Lair"),
    ("SHD", 80787, "Spell: Touch of the Shadows"),
    ("SHD", 81860, "Spell: Voice of Emoush"),
    ("SHD", 79408, "Tome of Soul Carapace"),
    ("SHM", 82663, "Spell Pack: Blood of Volkara"),
    ("SHM", 82662, "Spell Pack: Stillmoon Focus"),
    ("SHM", 82664, "Spell Pack: Talisman of Coalescence"),
    ("SHM", 82665, "Spell Pack: Talisman of the Cougar"),
    ("SHM", 50107, "Spell Pack: Wild Companions"),
    ("SHM", 80285, "Spell: Breath of Ju'rek"),
    ("SHM", 80288, "Spell: Curse of Emoush"),
    ("SHM", 80287, "Spell: Shadowy Sloth"),
    ("SHM", 80286, "Spell: Transcendental Torpor"),
    ("WAR", 88919, "Tome of Field Conqueror"),
    ("WAR", 79302, "Tome of Final Stand Discipline"),
    ("WAR", 80081, "Tome of Fourth Wind"),
    ("WAR", 88909, "Tome of Jeer"),
    ("WAR", 79310, "Tome of Maelstrom Blade"),
    ("WAR", 80080, "Tome of Maximum Effort"),
    ("WAR", 88910, "Tome of Roaring Hatred"),
    ("WAR", 88925, "Tome of Vanquisher's Aura"),
    ("WAR", 82654, "Tome Pack: Ancient: Malicious Onslaught"),
    ("WIZ", 82795, "Spell Pack: Bolster of the Sorcerer"),
    ("WIZ", 82797, "Spell Pack: Ethereal Weave"),
    ("WIZ", 82796, "Spell Pack: Supernal Skin"),
    ("WIZ", 80763, "Spell: Arcane Sanctuary"),
    ("WIZ", 80760, "Spell: Eruption of Telakemara"),
    ("WIZ", 79388, "Spell: Ether Blaze"),
    ("WIZ", 80761, "Spell: Evoker's Pyromantic Blade"),
    ("WIZ", 79129, "Spell: Serenity Harvest"),
    ("WIZ", 79390, "Spell: Wildmagic Salvo"),
]


def lua_str(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def spell_names_from_item(name: str) -> list[str]:
    name = name.strip()
    for prefix in ("Spell Pack: ", "Tome Pack: ", "Spell: ", "Song: ", "Tome of "):
        if name.startswith(prefix):
            return [name[len(prefix) :]]
    return [name]


def parse_existing_packs(class_body: str) -> list[dict]:
    """Return Pack entries in existing order from a class body."""
    packs: list[dict] = []
    for m in re.finditer(
        r"\['Pack(\d+)'\]\s*=\s*\{\s*item\s*=\s*'((?:\\'|[^'])*)'\s*,\s*"
        r"spells\s*=\s*\{([^}]*)\}\s*,?\s*\}",
        class_body,
        flags=re.S,
    ):
        item_line = m.group(2).replace("\\'", "'")
        if "/" in item_line:
            iname, iid_s = item_line.rsplit("/", 1)
            iid = int(iid_s)
        else:
            iname, iid = item_line, 0
        spells = []
        for sm in re.finditer(r"'((?:\\'|[^'])*)'", m.group(3)):
            spells.append(sm.group(1).replace("\\'", "'"))
        packs.append({"id": iid, "name": iname, "spells": spells})
    return packs


def format_pack_block(packs: list[dict], indent: str = "\t\t\t") -> str:
    parts = []
    for i, p in enumerate(packs, start=1):
        item_line = f"{p['name']}/{p['id']}"
        spell_lits = ", ".join(lua_str(s) for s in p["spells"])
        parts.append(
            f"{indent}['Pack{i}'] = {{\n"
            f"{indent}\titem = {lua_str(item_line)},\n"
            f"{indent}\tspells = {{{spell_lits}}},\n"
            f"{indent}}},"
        )
    return "\n".join(parts)


def merge_class_packs(existing: list[dict], vendor: list[tuple[int, str]]) -> list[dict]:
    by_id = {p["id"]: dict(p) for p in existing if p["id"]}
    order_ids = [p["id"] for p in existing if p["id"]]

    for iid, name in vendor:
        if iid in by_id:
            # Prefer merchant's exact item name; keep curated spell list.
            by_id[iid]["name"] = name
        else:
            by_id[iid] = {
                "id": iid,
                "name": name,
                "spells": spell_names_from_item(name),
            }
            order_ids.append(iid)

    # Stable: prior packs first, then newly appended vendor rows in vendor order.
    seen = set()
    out = []
    for iid in order_ids:
        if iid in seen:
            continue
        seen.add(iid)
        out.append(by_id[iid])
    return out


CLASS_ORDER = [
    "Bard",
    "Beastlord",
    "Berserker",
    "Cleric",
    "Druid",
    "Enchanter",
    "Magician",
    "Monk",
    "Necromancer",
    "Paladin",
    "Ranger",
    "Rogue",
    "Shadow Knight",
    "Shaman",
    "Warrior",
    "Wizard",
]


def main() -> None:
    text = BLOCK.read_text(encoding="utf-8")
    vendor_by_class: dict[str, list[tuple[int, str]]] = {}
    for abbr, iid, name in VENDOR_ROWS:
        cls = ABBREV_TO_CLASS[abbr]
        vendor_by_class.setdefault(cls, []).append((iid, name))

    max_pack = 0
    announce_names: set[str] = set()
    replacements: list[tuple[int, int, str]] = []

    for cls in CLASS_ORDER:
        rows = vendor_by_class.get(cls)
        if not rows:
            # Still parse existing packs for max_pack / announce.
            rows = []
        pat = re.compile(
            rf"\['{re.escape(cls)}'\]\s*=\s*\{{(.*?)(\n\t\t\['(?:{'|'.join(re.escape(c) for c in CLASS_ORDER + ['Main', 'Template'])})'\])",
            flags=re.S,
        )
        m = pat.search(text)
        if not m:
            raise SystemExit(f"class block not found: {cls}")
        body = m.group(1)
        existing = parse_existing_packs(body)
        merged = merge_class_packs(existing, rows) if rows else existing
        if not merged and not existing:
            continue
        max_pack = max(max_pack, len(merged))
        for p in merged:
            announce_names.add(p["name"])
        if not rows:
            continue

        pack_pat = re.compile(
            r"\n\t\t\t\['Pack1'\].*?(?=\n\t\t\t\['(?:Glyph|Aug)\d+'\])",
            flags=re.S,
        )
        pm = pack_pat.search(body)
        if not pm:
            raise SystemExit(f"Pack block not found in {cls}")
        new_pack = "\n" + format_pack_block(merged)
        new_body = body[: pm.start()] + new_pack + body[pm.end() :]
        replacements.append((m.start(1), m.end(1), new_body))
        print(f"  {cls}: {len(existing)} -> {len(merged)} packs")

    for start, end, new_body in sorted(replacements, key=lambda t: t[0], reverse=True):
        text = text[:start] + new_body + text[end:]

    pack_slots = ",".join(f"'Pack{i}'" for i in range(1, max_pack + 1))
    text, n = re.subn(
        r"\{Name='Spells',\s*Slots=\{[^}]*\}\}",
        f"{{Name='Spells', Slots={{{pack_slots},}}}}",
        text,
        count=1,
    )
    if n != 1:
        raise SystemExit(f"Spells slots replace failed n={n}")

    BLOCK.write_text(text, encoding="utf-8")
    print(f"Updated {BLOCK} max_pack={max_pack}")

    # Announce list: add missing Spell:/Song:/Tome lines; fix Ellowind / WAR pack names
    ini = ANNOUNCE_INI.read_text(encoding="utf-8")
    # Rename old announce keys if present
    ini = ini.replace(
        "Spell Pack: Ellowind=ANNOUNCE",
        "Spell Pack: Ellowind Hastening=ANNOUNCE",
    )
    ini = ini.replace(
        "Tome Pack: Malicious Onslaught Discipline=ANNOUNCE",
        "Tome Pack: Ancient: Malicious Onslaught=ANNOUNCE",
    )
    existing_keys = set(re.findall(r"^([^=\n]+)=ANNOUNCE\s*$", ini, flags=re.M))
    to_add = sorted(n for n in announce_names if n not in existing_keys)
    if to_add:
        # Insert before Tear of Kessdona in DoN section if present, else append near Tome Packs
        marker = "Tear of Kessdona=ANNOUNCE"
        block = "".join(f"{n}=ANNOUNCE\n" for n in to_add)
        if marker in ini:
            ini = ini.replace(marker, block + marker, 1)
        else:
            ini += "\n" + block
        ANNOUNCE_INI.write_text(ini, encoding="utf-8")
        print(f"Added {len(to_add)} announce entries")
    else:
        print("Announce ini already had all names")

    if ANNOUNCE_NAMES.exists():
        names = set(
            ln.strip() for ln in ANNOUNCE_NAMES.read_text(encoding="utf-8").splitlines() if ln.strip()
        )
        names |= announce_names
        # rename
        names.discard("Spell Pack: Ellowind")
        names.discard("Tome Pack: Malicious Onslaught Discipline")
        ANNOUNCE_NAMES.write_text("\n".join(sorted(names)) + "\n", encoding="utf-8")
        print(f"Updated {ANNOUNCE_NAMES} ({len(names)} names)")


if __name__ == "__main__":
    main()
