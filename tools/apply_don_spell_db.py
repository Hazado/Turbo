#!/usr/bin/env python3
"""Apply merchant 2089271 scrolleffect spell id/name onto don_bis_block Pack rows."""

from __future__ import annotations

import re
from pathlib import Path

BLOCK = Path(__file__).resolve().parents[1] / "tools" / "don_bis_block.lua"

# item_id -> (spell_id, spell_name) from spells_new via items.scrolleffect
# Packs omitted (scrolleffect -1); keep curated multi-spell lists.
SPELL_DB: dict[int, tuple[int, str]] = {
    79226: (10889, "Arcane Reprisal"),
    59925: (5038, "Battle Focus Discipline"),
    79251: (10915, "Bloodcurdling Scream"),
    50120: (10860, "Cleaving Madness Discipline"),
    50118: (10857, "Cry of Catastrophe"),
    80081: (15134, "Fourth Wind Discipline"),
    80280: (15120, "Rancorous Flurry Discipline"),
    50119: (10858, "Vigorous Axe Throw"),
    80281: (15122, "Wounding Rage"),
    81935: (15264, "Niv's Symphonic"),
    78739: (35234, "One Bard Band"),
    50157: (10940, "Squall Blade Flourish"),
    50156: (10939, "Endless Blades"),
    81933: (15261, "Feral Mettle"),
    81934: (15263, "Ravenous Ice"),
    78701: (10364, "Roaring Sleet"),
    81868: (15260, "Spiritual Enlightenment"),
    81867: (15257, "Swift Salve of the Stillmoon"),
    80284: (15140, "Chromablast"),
    124941: (25252, "Divine Redemption"),
    78149: (9812, "Elixir of Redemption"),
    78086: (9749, "Sound of Zeal"),
    80282: (15135, "Urgent Renewal"),
    80283: (15137, "Vigilant Censure"),
    80757: (15153, "Ascent Frost"),
    78200: (9863, "Breath of The Ascent"),
    80758: (15156, "Dawnflame"),
    80759: (15165, "Lunar Shadow"),
    117592: (10839, "Nature Seeker's Behest"),
    80756: (15152, "Sunburst Devotion"),
    50149: (10902, "Boon of the Sentinel"),
    80781: (15212, "Chromatic Chaos"),
    80783: (15216, "Hysteria"),
    80782: (15213, "Urgent Rune of Destiny"),
    80780: (10656, "Whispers of Emoush"),
    80766: (15191, "Blade Rend"),
    50144: (10890, "Burning Bladestorm"),
    79091: (10754, "Fickle Inferno"),
    80764: (15182, "Frantic Blaze"),
    80779: (15192, "Grant Battle Materiel"),
    80765: (15188, "Monolithic Strength"),
    88921: (15113, "Dragondance Discipline"),
    50117: (10854, "Fists of Thundercrest"),
    80078: (15095, "Grandmaster's Aura"),
    118654: (18904, "Phantom Whispers"),
    79445: (11923, "Stormfist Discipline"),
    80083: (15101, "Velocity Focus Discipline"),
    88901: (14797, "Wheel of Fists"),
    80786: (15230, "Malignant Plague"),
    80785: (15225, "Molten Pyre"),
    119599: (10906, "Pestilent Pustules"),
    78819: (10482, "Ritual of Blood"),
    78892: (10555, "Venom of the Accursed Nest"),
    80784: (15222, "Yearning of Death"),
    81864: (15251, "Benevolent Aura"),
    81862: (15248, "Brell's Unshakable Barricade"),
    81861: (15240, "Force of the Sacred"),
    81863: (15249, "Force of the Sentinel"),
    78039: (10919, "The Silent Decree"),
    79399: (11854, "Aegis of Righteousness"),
    81866: (15255, "Eyes of the Drake"),
    116082: (15082, "Heartshatter"),
    81865: (15254, "Ward of the Stalker"),
    80087: (15117, "Assailant Discipline"),
    80088: (15119, "Frenetic Stabbing Discipline"),
    80085: (15102, "Lithe Discipline"),
    88900: (40294, "Outlaw's Glare"),
    88902: (15115, "Pinpoint Weakness"),
    50116: (10852, "Twisted Fortune Discipline"),
    79236: (10851, "Vigorous Dagger Throw"),
    80788: (15233, "Blood of the Harbinger"),
    78565: (10913, "Grasp of Ju'rek"),
    78594: (10257, "Terror of Lavaspinner's Lair"),
    80787: (15231, "Touch of the Shadows"),
    81860: (15239, "Voice of Emoush"),
    79408: (11866, "Soul Carapace"),
    80285: (41232, "Breath of Shadows"),
    80288: (15147, "Curse of Emoush"),
    80287: (15144, "Shadowy Sloth"),
    80286: (15141, "Transcendental Torpor"),
    88919: (25036, "Field Conqueror"),
    79302: (10965, "Final Stand Discipline"),
    88909: (10848, "Jeer"),
    79310: (10973, "Maelstrom Blade"),
    80080: (15104, "Maximum Effort Discipline"),
    88910: (19537, "Roaring Hatred"),
    88925: (14351, "Vanquisher's Aura"),
    80763: (15180, "Arcane Sanctuary"),
    80760: (15167, "Eruption of Telakemara"),
    79388: (11835, "Ether Blaze"),
    80761: (15168, "Evoker's Pyromantic Blade"),
    79129: (10792, "Serenity Harvest"),
    79390: (11840, "Wildmagic Salvo"),
}


def lua_str(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main() -> None:
    text = BLOCK.read_text(encoding="utf-8")
    updated = 0

    # Match Pack blocks: item = 'Name/ID', spells = {...},
    pat = re.compile(
        r"(\['Pack\d+'\]\s*=\s*\{\s*item\s*=\s*'((?:\\'|[^'])*)'\s*,\s*"
        r"spells\s*=\s*)\{([^}]*)\}(\s*,?\s*)\}",
        flags=re.S,
    )

    def repl(m: re.Match) -> str:
        nonlocal updated
        item_line = m.group(2).replace("\\'", "'")
        if "/" not in item_line:
            return m.group(0)
        _name, iid_s = item_line.rsplit("/", 1)
        try:
            iid = int(iid_s)
        except ValueError:
            return m.group(0)
        row = SPELL_DB.get(iid)
        if not row:
            return m.group(0)
        sid, sname = row
        updated += 1
        # group4 is the original trailing ",\n\t\t\t" before Pack's closing brace.
        trail = m.group(4) or ""
        if not trail.strip().startswith(","):
            trail = "," + trail
        return (
            f"{m.group(1)}{{{lua_str(sname)}}},\n"
            f"\t\t\t\tspell_ids = {{{sid}}}"
            f"{trail}}}"
        )

    text2, n = pat.subn(repl, text)
    # Fix accidental double braces from replace - verify output shape
    # Our return ends with group4 + "}"  where group4 is ",\n\t\t\t" or similar before closing }
    # Original: spells = {..}, }  -> spells = {'X'}, spell_ids = {N}, }

    if updated == 0:
        raise SystemExit("no pack rows updated")

    BLOCK.write_text(text2, encoding="utf-8")
    print(f"Updated {updated} Pack rows with DB spell name/id ({n} regex hits)")


if __name__ == "__main__":
    main()
