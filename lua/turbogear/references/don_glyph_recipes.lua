-- turbogear/references/don_glyph_recipes.lua
-- DoN glyph combines + the OoW-era Imbued Rune combines they build on.
--
-- Tier 1 (glyphs):  combined in the Lodestone of Mnemonic Binding, no-fail.
--   Mnemonic glyphs: Formless Mnemonic Glyph + class template.
--   Imbued glyphs:   Imbued Rune (see rune_recipes) + class template.
--   Templates come from opening DoN Spell/Tome Packs.
-- Tier 2 (runes):   Research combines (trivial 300, no-fail) in the
--   Concordance of Research. These are pre-DoN (OoW research) items the
--   glyph upgrades. Every rune needs a Receptive Runic Tablet (9615) -
--   the imbued-tier bottleneck, like Formless Mnemonic Glyph (81948) is
--   for mnemonics. Formless has no recipe: it DROPS from Dark Reign named that
--   are script-spawned into DoN mission instances (their spawn-table home zone,
--   freeportarena, is just a staging zone - do not farm there). Also drops from
--   Gimblax (delveb) and Wong Li (stillmoona).
--
-- glyph_spell_id: the spell the glyph CASTS when clicked (items.clickeffect).
-- Glyphs are permanent clickies, not consumables: ownership stays item-based,
-- and the clicky spell never enters the spellbook, so it does not interfere
-- with name-based Book/CombatAbility checks for the scribed base spell.

return {
  glyph_container = { name = 'Lodestone of Mnemonic Binding', id = 66909 },
  rune_container  = { name = 'Concordance of Research', id = 17504 },
  formless = {
    name = 'Formless Mnemonic Glyph', id = 81948,
    source = 'Drops: Dark Reign named inside DoN mission instances; also Gimblax (delveb), Wong Li (stillmoona)',
  },
  glyphs = {
    {
      name = 'Imbued Glyph: Aegis of Vie', id = 76567, kind = 'imbued', glyph_spell_id = 15510,
      recipes = {
        { recipe_id = 129133, components = {
          { name = 'Imbued Rune of Vie', id = 9552, qty = 1 },
          { name = 'Imbued Template: Aegis of Vie', id = 71771, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Ancient: Annihilator\'s Volley', id = 80076, kind = 'imbued', glyph_spell_id = 18016,
      recipes = {
        { recipe_id = 129188, components = {
          { name = 'Imbued Rune of Overpowering Frenzy', id = 9551, qty = 1 },
          { name = 'Imbued Template: Ancient: Annihilator\'s Volley', id = 76561, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Ancient: Arachnid Fang', id = 80074, kind = 'imbued', glyph_spell_id = 18013,
      recipes = {
        { recipe_id = 129186, components = {
          { name = 'Imbued Rune of Dragon Fang', id = 9549, qty = 1 },
          { name = 'Imbued Template: Ancient: Arachnid Fang', id = 76538, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Ancient: Incursion', id = 80075, kind = 'imbued', glyph_spell_id = 18014,
      recipes = {
        { recipe_id = 129187, components = {
          { name = 'Imbued Rune of Assault', id = 9550, qty = 1 },
          { name = 'Imbued Template: Ancient: Incursion', id = 76560, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Ancient: Malicious Onslaught', id = 80073, kind = 'imbued', glyph_spell_id = 18011,
      recipes = {
        { recipe_id = 129185, components = {
          { name = 'Imbued Rune of Brutal Onslaught', id = 9548, qty = 1 },
          { name = 'Imbued Template: Ancient: Malicious Onslaught', id = 76537, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Echoes of the Ancient', id = 80072, kind = 'imbued', glyph_spell_id = 18010,
      recipes = {
        { recipe_id = 129184, components = {
          { name = 'Imbued Rune of Echoes', id = 9604, qty = 1 },
          { name = 'Imbued Template: Echoes of the Ancient', id = 76536, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Edict of Tashan', id = 79534, kind = 'imbued', glyph_spell_id = 18002,
      recipes = {
        { recipe_id = 129179, components = {
          { name = 'Imbued Rune of Tashan\'s Echo', id = 9557, qty = 1 },
          { name = 'Imbued Template: Edict of Tashan', id = 71776, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Ethereal Weave', id = 79523, kind = 'imbued', glyph_spell_id = 16918,
      recipes = {
        { recipe_id = 129176, components = {
          { name = 'Imbued Rune of Mana Weave', id = 9555, qty = 1 },
          { name = 'Imbued Template: Ethereal Weave', id = 71774, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Goner\'s Urgent Renewal', id = 79526, kind = 'imbued', glyph_spell_id = 16919,
      recipes = {
        { recipe_id = 129177, components = {
          { name = 'Imbued Rune of Jerikor\'s Renewal', id = 9556, qty = 1 },
          { name = 'Imbued Template: Goner\'s Urgent Renewal', id = 71775, qty = 1 },
        } },
        { recipe_id = 129178, components = {
          { name = 'Imbued Rune of Dark Salve', id = 9558, qty = 1 },
          { name = 'Imbued Template: Goner\'s Urgent Renewal', id = 71775, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Jolting Thunderkicks', id = 80066, kind = 'imbued', glyph_spell_id = 18007,
      recipes = {
        { recipe_id = 129182, components = {
          { name = 'Imbued Rune of Jolting Snapkicks', id = 9602, qty = 1 },
          { name = 'Imbued Template: Jolting Thunderkicks', id = 71781, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Sha\'s Urgent Renewal', id = 80070, kind = 'imbued', glyph_spell_id = 18008,
      recipes = {
        { recipe_id = 129183, components = {
          { name = 'Imbued Rune of Mikkily\'s Healing', id = 9603, qty = 1 },
          { name = 'Imbued Template: Sha\'s Urgent Renewal', id = 71782, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Sun\'s Blistering Corona', id = 79520, kind = 'imbued', glyph_spell_id = 15513,
      recipes = {
        { recipe_id = 129175, components = {
          { name = 'Imbued Rune of the Immolating Sun', id = 9554, qty = 1 },
          { name = 'Imbued Template: Sun\'s Blistering Corona', id = 71773, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Talisman of the Cougar', id = 76572, kind = 'imbued', glyph_spell_id = 15512,
      recipes = {
        { recipe_id = 129174, components = {
          { name = 'Imbued Rune of the Panther', id = 9553, qty = 1 },
          { name = 'Imbued Template: Talisman of the Cougar', id = 71772, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Theft of Misery', id = 79537, kind = 'imbued', glyph_spell_id = 18004,
      recipes = {
        { recipe_id = 129180, components = {
          { name = 'Imbued Rune of Agony and Hate', id = 9601, qty = 1 },
          { name = 'Imbued Template: Theft of Misery', id = 71778, qty = 1 },
        } },
      },
    },
    {
      name = 'Imbued Glyph: Wave of Stillmoon', id = 79540, kind = 'imbued', glyph_spell_id = 18005,
      recipes = {
        { recipe_id = 129181, components = {
          { name = 'Imbued Rune of Piety', id = 9600, qty = 1 },
          { name = 'Imbued Template: Wave of the Stillmoon', id = 71779, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Allegiance', id = 76563, kind = 'mnemonic', glyph_spell_id = 15450,
      recipes = {
        { recipe_id = 129119, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Allegiance', id = 67750, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Armor of the Sacred', id = 76566, kind = 'mnemonic', glyph_spell_id = 15457,
      recipes = {
        { recipe_id = 129132, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Armor of the Sacred', id = 67753, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Armor of the Savior', id = 79538, kind = 'mnemonic', glyph_spell_id = 15493,
      recipes = {
        { recipe_id = 129164, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Armor of the Savior', id = 71761, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Blessing of Moss', id = 79519, kind = 'mnemonic', glyph_spell_id = 15469,
      recipes = {
        { recipe_id = 129150, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Blessing of Moss', id = 67762, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Blessing of Spiritoak', id = 78227, kind = 'mnemonic', glyph_spell_id = 15466,
      recipes = {
        { recipe_id = 129148, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Blessing of Spiritoak', id = 67760, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Blood of Volkara', id = 76570, kind = 'mnemonic', glyph_spell_id = 15461,
      recipes = {
        { recipe_id = 129145, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Blood of Volkara', id = 67757, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Bolster of the Sorcerer', id = 79521, kind = 'mnemonic', glyph_spell_id = 15470,
      recipes = {
        { recipe_id = 129151, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Bolster of the Sorcerer', id = 67763, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Call of Storms', id = 80065, kind = 'mnemonic', glyph_spell_id = 15499,
      recipes = {
        { recipe_id = 129168, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Call of Storms', id = 71765, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Cantata of Nife', id = 80071, kind = 'mnemonic', glyph_spell_id = 15507,
      recipes = {
        { recipe_id = 129172, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Cantata of Nife', id = 71769, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Circle of Magmaskin', id = 79525, kind = 'mnemonic', glyph_spell_id = 15475,
      recipes = {
        { recipe_id = 129154, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Circle of Magmaskin', id = 67766, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Cloak of the Corrupter', id = 79535, kind = 'mnemonic', glyph_spell_id = 15491,
      recipes = {
        { recipe_id = 129162, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Cloak of the Corrupter', id = 71759, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Dull Agony', id = 79528, kind = 'mnemonic', glyph_spell_id = 15478,
      recipes = {
        { recipe_id = 129161, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Dull Agony', id = 71758, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Growl of the Mountain Puma', id = 80069, kind = 'mnemonic', glyph_spell_id = 15506,
      recipes = {
        { recipe_id = 129171, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Growl of the Mountain Puma', id = 71768, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Guard of Thundercrest', id = 80064, kind = 'mnemonic', glyph_spell_id = 15498,
      recipes = {
        { recipe_id = 129167, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Guard of Thundercrest', id = 71764, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Hand of Allegiance', id = 76564, kind = 'mnemonic', glyph_spell_id = 15452,
      recipes = {
        { recipe_id = 129130, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Hand of Allegiance', id = 67751, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Hastening of Ellowind', id = 79532, kind = 'mnemonic', glyph_spell_id = 15487,
      recipes = {
        { recipe_id = 129158, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Hastening of Ellowind', id = 71755, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Mossy Vigor', id = 79518, kind = 'mnemonic', glyph_spell_id = 15467,
      recipes = {
        { recipe_id = 129149, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Mossy Vigor', id = 67761, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Presidio of the Seer', id = 79533, kind = 'mnemonic', glyph_spell_id = 15488,
      recipes = {
        { recipe_id = 129159, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Presidio of the Seer', id = 71756, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Roaring Spirit of Tirranun', id = 80068, kind = 'mnemonic', glyph_spell_id = 15502,
      recipes = {
        { recipe_id = 129170, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Roaring Spirit of Tirranun', id = 71767, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Sacrilege of the Wraith', id = 79527, kind = 'mnemonic', glyph_spell_id = 15476,
      recipes = {
        { recipe_id = 129160, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Sacrilege of the Wraith', id = 71757, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Seer\'s Intuition', id = 79529, kind = 'mnemonic', glyph_spell_id = 15479,
      recipes = {
        { recipe_id = 129155, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Seer\'s Intuition', id = 69180, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Shroud of the Accursed', id = 79536, kind = 'mnemonic', glyph_spell_id = 15492,
      recipes = {
        { recipe_id = 129163, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Shroud of the Accursed', id = 71760, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Snarl of the Predator', id = 80063, kind = 'mnemonic', glyph_spell_id = 15496,
      recipes = {
        { recipe_id = 129166, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Snarl of the Predator', id = 71763, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Speed of Ellowind', id = 79531, kind = 'mnemonic', glyph_spell_id = 15485,
      recipes = {
        { recipe_id = 129157, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Speed of Ellowind', id = 71754, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Spiritoak Skin', id = 76573, kind = 'mnemonic', glyph_spell_id = 15464,
      recipes = {
        { recipe_id = 129147, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Spiritoak Skin', id = 67759, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Spiritual Vibrance', id = 80067, kind = 'mnemonic', glyph_spell_id = 15501,
      recipes = {
        { recipe_id = 129169, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Spiritual Vibrance', id = 71766, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Stillmoon Focusing', id = 76568, kind = 'mnemonic', glyph_spell_id = 15458,
      recipes = {
        { recipe_id = 129143, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Stillmoon Focusing', id = 67755, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Supernal Skin', id = 79522, kind = 'mnemonic', glyph_spell_id = 15472,
      recipes = {
        { recipe_id = 129152, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Supernal Skin', id = 67764, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Symbol of Elushar', id = 76565, kind = 'mnemonic', glyph_spell_id = 15453,
      recipes = {
        { recipe_id = 129131, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Symbol of Elushar', id = 67752, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Symphony of Sound', id = 80084, kind = 'mnemonic', glyph_spell_id = 15509,
      recipes = {
        { recipe_id = 129173, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Symphony of Sound', id = 71770, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Talisman of Coalescence', id = 76571, kind = 'mnemonic', glyph_spell_id = 15463,
      recipes = {
        { recipe_id = 129146, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Talisman of Coalescence', id = 67758, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Talisman of the Stillmoon', id = 76569, kind = 'mnemonic', glyph_spell_id = 15460,
      recipes = {
        { recipe_id = 129144, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Talisman of the Stillmoon', id = 67756, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Virtuous Fervor', id = 79539, kind = 'mnemonic', glyph_spell_id = 15495,
      recipes = {
        { recipe_id = 129165, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Virtuous Fervor', id = 71762, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Voice of Intuition', id = 79530, kind = 'mnemonic', glyph_spell_id = 15484,
      recipes = {
        { recipe_id = 129156, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Voice of Intuition', id = 69889, qty = 1 },
        } },
      },
    },
    {
      name = 'Mnemonic Glyph: Ward of the Conjurer', id = 79524, kind = 'mnemonic', glyph_spell_id = 15473,
      recipes = {
        { recipe_id = 129153, components = {
          { name = 'Formless Mnemonic Glyph', id = 81948, qty = 1 },
          { name = 'Mnemonic Template: Ward of the Conjurer', id = 67765, qty = 1 },
        } },
      },
    },
  },
  rune_recipes = {
    {
      name = 'Imbued Rune of Agony and Hate', id = 9601, recipe_id = 128034,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Infliction', id = 41539, qty = 1 },
        { name = 'Ink of Retort', id = 38506, qty = 1 },
        { name = 'Quill of the Dread Lord', id = 93523, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Theft of Agony', id = 77990, qty = 1 },
        { name = 'Spell: Theft of Hate', id = 77080, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Assault', id = 9550, recipe_id = 128024,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Infliction', id = 41539, qty = 1 },
        { name = 'Ink of Striking', id = 41537, qty = 1 },
        { name = 'Quill of the Deceiver', id = 41527, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Tome of Assault', id = 119715, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Brutal Onslaught', id = 9548, recipe_id = 128022,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Barrage', id = 41548, qty = 1 },
        { name = 'Ink of Smashing', id = 41538, qty = 1 },
        { name = 'Quill of the Overlord', id = 41528, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Tome of Brutal Onslaught Discipline', id = 79441, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Dark Salve', id = 9558, recipe_id = 128032,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Decay', id = 38509, qty = 1 },
        { name = 'Ink of the Companion', id = 93583, qty = 1 },
        { name = 'Quill of the Arch Lich', id = 93516, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Dark Salve', id = 77171, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Dragon Fang', id = 9549, recipe_id = 128023,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Finesse', id = 41544, qty = 1 },
        { name = 'Ink of Pain', id = 93587, qty = 1 },
        { name = 'Quill of the Transcendent', id = 41526, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Tome of Dragon Fang', id = 76034, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Echoes', id = 9604, recipe_id = 128037,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Barrage', id = 41548, qty = 1 },
        { name = 'Ink of Screening', id = 38508, qty = 1 },
        { name = 'Quill of the Maestro', id = 93525, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Song: Echoes of the Past', id = 17658, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Jerikor\'s Renewal', id = 9556, recipe_id = 128030,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Rainbows', id = 93564, qty = 1 },
        { name = 'Ink of the Companion', id = 93583, qty = 1 },
        { name = 'Quill of the Arch Convoker', id = 93515, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Renewal of Jerikor', id = 77225, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Jolting Snapkicks', id = 9602, recipe_id = 128035,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Forgetfulness', id = 93589, qty = 1 },
        { name = 'Ink of Striking', id = 41537, qty = 1 },
        { name = 'Quill of the Forest Stalker', id = 93522, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Tome of Jolting Snapkicks', id = 116021, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Mana Weave', id = 9555, recipe_id = 128029,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Infliction', id = 41539, qty = 1 },
        { name = 'Ink of Pain', id = 93587, qty = 1 },
        { name = 'Quill of the Arcanist', id = 93517, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Mana Weave', id = 77925, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Mikkily\'s Healing', id = 9603, recipe_id = 128036,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of the Companion', id = 93583, qty = 1 },
        { name = 'Ink of Tranquility', id = 93590, qty = 1 },
        { name = 'Quill of the Feral Lord', id = 93521, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Healing of Mikkily', id = 77255, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Overpowering Frenzy', id = 9551, recipe_id = 128025,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Barrage', id = 41548, qty = 1 },
        { name = 'Ink of Breaching', id = 41552, qty = 1 },
        { name = 'Quill of the Fury', id = 41525, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Tome of Overpowering Frenzy', id = 39308, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Piety', id = 9600, recipe_id = 128033,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Reach', id = 41547, qty = 1 },
        { name = 'Ink of Tunare', id = 93573, qty = 1 },
        { name = 'Quill of the Lord Protector', id = 93524, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Wave of Piety', id = 77043, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Tashan\'s Echo', id = 9557, recipe_id = 128031,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Affliction', id = 41551, qty = 1 },
        { name = 'Ink of Breaching', id = 41552, qty = 1 },
        { name = 'Quill of the Coercer', id = 93514, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Echo of Tashan', id = 78945, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of Vie', id = 9552, recipe_id = 128026,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Obstruction', id = 41542, qty = 1 },
        { name = 'Ink of Pain', id = 93587, qty = 1 },
        { name = 'Quill of the Archon', id = 93518, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Panoply of Vie', id = 77012, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of the Immolating Sun', id = 9554, recipe_id = 128028,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Affliction', id = 41551, qty = 1 },
        { name = 'Ink of Ro', id = 93558, qty = 1 },
        { name = 'Quill of the Storm Warden', id = 93519, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Sun\'s Corona', id = 77093, qty = 1 },
      },
    },
    {
      name = 'Imbued Rune of the Panther', id = 9553, recipe_id = 128027,
      tradeskill = 'research', trivial = 300, nofail = true,
      components = {
        { name = 'Ink of Pain', id = 93587, qty = 1 },
        { name = 'Ink of Proficiency', id = 41550, qty = 1 },
        { name = 'Quill of the Prophet', id = 93520, qty = 1 },
        { name = 'Receptive Runic Tablet', id = 9615, qty = 1 },
        { name = 'Spell: Talisman of the Panther', id = 78311, qty = 1 },
      },
    },
  },
}
