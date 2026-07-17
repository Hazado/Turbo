-- turbogear/references/don_spell_catalog.lua
-- DoN spells, songs, tomes and packs per class
-- Ownership semantics (per entry):
--   single: item held anywhere OR ability scribed (Me.Book / Me.CombatAbility).
--   pack:   pack item held OR EVERY ability satisfied individually
--           (its scroll item held OR its ability scribed).
-- ability strings are canonical spells_new names - do NOT derive from item names

return {
  ['Warrior'] = {
    packs = {
      { id = 82654, name = 'Tome Pack: Ancient: Malicious Onslaught',
        abilities = {
          { item = 78424, item_name = 'Tome of Ancient: Malicious Onslaught', spell_id = 10849, ability = 'Ancient: Malicious Onslaught' },
        } },
    },
    singles = {
      { id = 88919, name = 'Tome of Field Conqueror', spell_id = 25036, ability = 'Field Conqueror' },
      { id = 79302, name = 'Tome of Final Stand Discipline', spell_id = 10965, ability = 'Final Stand Discipline' },
      { id = 80081, name = 'Tome of Fourth Wind', spell_id = 15134, ability = 'Fourth Wind Discipline' },
      { id = 88909, name = 'Tome of Jeer', spell_id = 10848, ability = 'Jeer' },
      { id = 79310, name = 'Tome of Maelstrom Blade', spell_id = 10973, ability = 'Maelstrom Blade' },
      { id = 80080, name = 'Tome of Maximum Effort', spell_id = 15104, ability = 'Maximum Effort Discipline' },
      { id = 88910, name = 'Tome of Roaring Hatred', spell_id = 19537, ability = 'Roaring Hatred' },
      { id = 88925, name = 'Tome of Vanquisher\'s Aura', spell_id = 14351, ability = 'Vanquisher\'s Aura' },
    },
  },
  ['Cleric'] = {
    packs = {
      { id = 82661, name = 'Spell Pack: Aegis of Vie',
        abilities = {
          { item = 78079, item_name = 'Spell: Aegis of Vie', spell_id = 9742, ability = 'Aegis of Vie' },
        } },
      { id = 82658, name = 'Spell Pack: Allegiance',
        abilities = {
          { item = 78067, item_name = 'Spell: Allegiance', spell_id = 9730, ability = 'Allegiance' },
          { item = 78146, item_name = 'Spell: Hand of Allegiance', spell_id = 9809, ability = 'Hand of Allegiance' },
          { item = 78046, item_name = 'Spell: Symbol of Elushar', spell_id = 9709, ability = 'Symbol of Elushar' },
        } },
      { id = 82660, name = 'Spell Pack: Armor of the Sacred',
        abilities = {
          { item = 78040, item_name = 'Spell: Armor of the Sacred', spell_id = 9703, ability = 'Armor of the Sacred' },
        } },
    },
    singles = {
      { id = 80284, name = 'Spell: Chromablast', spell_id = 15140, ability = 'Chromablast' },
      { id = 124941, name = 'Spell: Divine Redemption', spell_id = 25252, ability = 'Divine Redemption' },
      { id = 78149, name = 'Spell: Elixir of Redemption', spell_id = 9812, ability = 'Elixir of Redemption' },
      { id = 78086, name = 'Spell: Sound of Zeal', spell_id = 9749, ability = 'Sound of Zeal' },
      { id = 80282, name = 'Spell: Urgent Renewal', spell_id = 15135, ability = 'Urgent Renewal' },
      { id = 80283, name = 'Spell: Vigilant Censure', spell_id = 15137, ability = 'Vigilant Censure' },
    },
  },
  ['Paladin'] = {
    packs = {
      { id = 82810, name = 'Spell Pack: Armor of the Savior',
        abilities = {
          { item = 78534, item_name = 'Spell: Armor of the Savior', spell_id = 10197, ability = 'Armor of the Savior' },
        } },
      { id = 82811, name = 'Spell Pack: Virtuous Fervor',
        abilities = {
          { item = 78552, item_name = 'Spell: Virtuous Fervor', spell_id = 10215, ability = 'Virtuous Fervor' },
        } },
      { id = 82812, name = 'Spell Pack: Wave of the Stillmoon',
        abilities = {
          { item = 78543, item_name = 'Spell: Wave of the Stillmoon', spell_id = 10206, ability = 'Wave of the Stillmoon' },
        } },
    },
    singles = {
      { id = 81864, name = 'Spell: Benevolent Aura', spell_id = 15251, ability = 'Benevolent Aura' },
      { id = 81862, name = 'Spell: Brell\'s Unshakable Barricade', spell_id = 15248, ability = 'Brell\'s Unshakable Barricade' },
      { id = 81861, name = 'Spell: Force of the Sacred', spell_id = 15240, ability = 'Force of the Sacred' },
      { id = 81863, name = 'Spell: Force of the Sentinel', spell_id = 15249, ability = 'Force of the Sentinel' },
      { id = 78039, name = 'Spell: The Silent Decree', spell_id = 10919, ability = 'The Silent Decree' },
      { id = 79399, name = 'Tome of Aegis of Righteousness', spell_id = 11854, ability = 'Aegis of Righteousness' },
    },
  },
  ['Ranger'] = {
    packs = {
      { id = 82815, name = 'Spell Pack: Call of Storms',
        abilities = {
          { item = 78471, item_name = 'Spell: Call of Storms', spell_id = 10134, ability = 'Call of Storms' },
        } },
      { id = 50150, name = 'Spell Pack: Flame and Frost',
        abilities = {
          { item = 78453, item_name = 'Spell: Embers of the Delve', spell_id = 10116, ability = 'Embers of the Delve' },
          { item = 78441, item_name = 'Spell: Frost of the Ascent', spell_id = 10104, ability = 'Frost of the Ascent' },
        } },
      { id = 82814, name = 'Spell Pack: Guard of Thundercrest',
        abilities = {
          { item = 116076, item_name = 'Spell: Guard of Thundercrest', spell_id = 15076, ability = 'Guard of Thundercrest' },
        } },
      { id = 82813, name = 'Spell Pack: Snarl of the Predator',
        abilities = {
          { item = 78450, item_name = 'Spell: Snarl of the Predator', spell_id = 10113, ability = 'Snarl of the Predator' },
        } },
      { id = 82816, name = 'Tome Pack: Jolting Thunderkicks',
        abilities = {
          { item = 71780, item_name = 'Tome of Jolting Thunderkicks', spell_id = 15078, ability = 'Jolting Thunderkicks' },
        } },
    },
    singles = {
      { id = 81866, name = 'Spell: Eyes of the Drake', spell_id = 15255, ability = 'Eyes of the Drake' },
      { id = 116082, name = 'Spell: Heartshatter', spell_id = 15082, ability = 'Heartshatter' },
      { id = 81867, name = 'Spell: Swift Salve of the Stillmoon', spell_id = 15257, ability = 'Swift Salve of the Stillmoon' },
      { id = 81865, name = 'Spell: Ward of the Stalker', spell_id = 15254, ability = 'Ward of the Stalker' },
    },
  },
  ['Shadow Knight'] = {
    packs = {
      { id = 82807, name = 'Spell Pack: Cloak of the Corrupter',
        abilities = {
          { item = 78637, item_name = 'Spell: Cloak of the Corrupter', spell_id = 10300, ability = 'Cloak of the Corrupter' },
        } },
      { id = 82808, name = 'Spell Pack: Shroud of the Accursed',
        abilities = {
          { item = 78588, item_name = 'Spell: Shroud of the Accursed', spell_id = 10251, ability = 'Shroud of the Accursed' },
        } },
      { id = 82809, name = 'Spell Pack: Theft of Misery',
        abilities = {
          { item = 71777, item_name = 'Spell: Theft of Misery', spell_id = 15073, ability = 'Theft of Misery' },
        } },
    },
    singles = {
      { id = 80788, name = 'Spell: Blood of the Harbinger', spell_id = 15233, ability = 'Blood of the Harbinger' },
      { id = 78565, name = 'Spell: Grasp of Ju\'rek', spell_id = 10913, ability = 'Grasp of Ju\'rek' },
      { id = 78594, name = 'Spell: Terror of Lavaspinner\'s Lair', spell_id = 10257, ability = 'Terror of Lavaspinner\'s Lair' },
      { id = 80787, name = 'Spell: Touch of the Shadows', spell_id = 15231, ability = 'Touch of the Shadows' },
      { id = 81860, name = 'Spell: Voice of Emoush', spell_id = 15239, ability = 'Voice of Emoush' },
      { id = 79408, name = 'Tome of Soul Carapace', spell_id = 11866, ability = 'Soul Carapace' },
    },
  },
  ['Druid'] = {
    packs = {
      { id = 82777, name = 'Spell Pack: Clumped Moss',
        abilities = {
          { item = 116235, item_name = 'Spell: Mossy Vigor', spell_id = 15235, ability = 'Mossy Vigor' },
          { item = 116280, item_name = 'Spell: Blessing of Moss', spell_id = 15280, ability = 'Blessing of Moss' },
        } },
      { id = 82688, name = 'Spell Pack: Spiritoaks',
        abilities = {
          { item = 78209, item_name = 'Spell: Spiritoak Skin', spell_id = 9872, ability = 'Spiritoak Skin' },
          { item = 78266, item_name = 'Spell: Blessing of Spiritoak', spell_id = 9929, ability = 'Blessing of Spiritoak' },
        } },
      { id = 82778, name = 'Spell Pack: Sun\'s Blistering Corona',
        abilities = {
          { item = 78161, item_name = 'Spell: Sun\'s Blistering Corona', spell_id = 9824, ability = 'Sun\'s Blistering Corona' },
        } },
    },
    singles = {
      { id = 80757, name = 'Spell: Ascent Frost', spell_id = 15153, ability = 'Ascent Frost' },
      { id = 78200, name = 'Spell: Breath of the Ascent', spell_id = 9863, ability = 'Breath of The Ascent' },
      { id = 80758, name = 'Spell: Dawnflame', spell_id = 15156, ability = 'Dawnflame' },
      { id = 80759, name = 'Spell: Lunar Shadow', spell_id = 15165, ability = 'Lunar Shadow' },
      { id = 117592, name = 'Spell: Nature Seeker\'s Behest', spell_id = 10839, ability = 'Nature Seeker\'s Behest' },
      { id = 80756, name = 'Spell: Sunburst Devotion', spell_id = 15152, ability = 'Sunburst Devotion' },
    },
  },
  ['Monk'] = {
    packs = {
      { id = 82655, name = 'Tome Pack: Ancient: Arachnid Fang', off_vendor = true,
        abilities = {
          { item = 79282, item_name = 'Tome of Ancient: Arachnid Fang', spell_id = 10855, ability = 'Ancient: Arachnid Fang' },
        } },
    },
    singles = {
      { id = 79226, name = 'Tome of Arcane Reprisal', spell_id = 10889, ability = 'Arcane Reprisal' },
      { id = 88921, name = 'Tome of Dragondance Discipline', spell_id = 15113, ability = 'Dragondance Discipline' },
      { id = 50117, name = 'Tome of Fists of Thundercrest', spell_id = 10854, ability = 'Fists of Thundercrest' },
      { id = 80081, name = 'Tome of Fourth Wind', spell_id = 15134, ability = 'Fourth Wind Discipline' },
      { id = 80078, name = 'Tome of Grandmaster\'s Aura', spell_id = 15095, ability = 'Grandmaster\'s Aura' },
      { id = 118654, name = 'Tome of Phantom Whispers', spell_id = 18904, ability = 'Phantom Whispers' },
      { id = 79445, name = 'Tome of Stormfist Discipline', spell_id = 11923, ability = 'Stormfist Discipline' },
      { id = 80083, name = 'Tome of Velocity Focus', spell_id = 15101, ability = 'Velocity Focus Discipline' },
      { id = 88901, name = 'Tome of Wheel of Fists', spell_id = 14797, ability = 'Wheel of Fists' },
    },
  },
  ['Bard'] = {
    packs = {
      { id = 82821, name = 'Spell Pack: Cantata of Nife',
        abilities = {
          { item = 50158, item_name = 'Song: Cantata of Nife', spell_id = 10948, ability = 'Cantata of Nife' },
          { item = 50159, item_name = 'Song: Chorus of Nife', spell_id = 10949, ability = 'Chorus of Nife' },
        } },
      { id = 82823, name = 'Spell Pack: Echoes of the Ancient',
        abilities = {
          { item = 76562, item_name = 'Song: Echoes of the Ancient', spell_id = 15081, ability = 'Echoes of the Ancient' },
        } },
      { id = 82822, name = 'Spell Pack: Symphony of Sound',
        abilities = {
          { item = 50155, item_name = 'Song: Symphony of Sound', spell_id = 10936, ability = 'Symphony of Sound' },
        } },
    },
    singles = {
      { id = 81935, name = 'Song: Niv\'s Symphonic', spell_id = 15264, ability = 'Niv\'s Symphonic' },
      { id = 78739, name = 'Song: One Bard Band', spell_id = 35234, ability = 'One Bard Band' },
      { id = 50157, name = 'Song: Squall Blade', spell_id = 10940, ability = 'Squall Blade Flourish' },
      { id = 79226, name = 'Tome of Arcane Reprisal', spell_id = 10889, ability = 'Arcane Reprisal' },
      { id = 50156, name = 'Tome of Endless Blades', spell_id = 10939, ability = 'Endless Blades' },
    },
  },
  ['Rogue'] = {
    packs = {
      { id = 82656, name = 'Tome Pack: Ancient: Incursion', off_vendor = true,
        abilities = {
          { item = 88920, item_name = 'Tome of Ancient: Incursion', spell_id = 35299, ability = 'Ancient: Incursion' },
        } },
    },
    singles = {
      { id = 79226, name = 'Tome of Arcane Reprisal', spell_id = 10889, ability = 'Arcane Reprisal' },
      { id = 80087, name = 'Tome of Assailant Discipline', spell_id = 15117, ability = 'Assailant Discipline' },
      { id = 80081, name = 'Tome of Fourth Wind', spell_id = 15134, ability = 'Fourth Wind Discipline' },
      { id = 80088, name = 'Tome of Frenetic Stabbing Discipline', spell_id = 15119, ability = 'Frenetic Stabbing Discipline' },
      { id = 80085, name = 'Tome of Lithe Discipline', spell_id = 15102, ability = 'Lithe Discipline' },
      { id = 88900, name = 'Tome of Outlaw\'s Glare', spell_id = 40294, ability = 'Outlaw\'s Glare' },
      { id = 88902, name = 'Tome of Pinpoint Weakness', spell_id = 15115, ability = 'Pinpoint Weakness' },
      { id = 50116, name = 'Tome of Twisted Fortune Discipline', spell_id = 10852, ability = 'Twisted Fortune Discipline' },
      { id = 79236, name = 'Tome of Vigorous Dagger Throw', spell_id = 10851, ability = 'Vigorous Dagger Throw' },
    },
  },
  ['Shaman'] = {
    packs = {
      { id = 82663, name = 'Spell Pack: Blood of Volkara',
        abilities = {
          { item = 55745, item_name = 'Spell: Blood of Volkara', spell_id = 10818, ability = 'Blood of Volkara' },
        } },
      { id = 82662, name = 'Spell Pack: Stillmoon Focus',
        abilities = {
          { item = 78342, item_name = 'Spell: Stillmoon Focusing', spell_id = 10005, ability = 'Stillmoon Focusing' },
          { item = 78393, item_name = 'Spell: Talisman of the Stillmoon', spell_id = 10056, ability = 'Talisman of the Stillmoon' },
        } },
      { id = 82664, name = 'Spell Pack: Talisman of Coalescence',
        abilities = {
          { item = 117580, item_name = 'Spell: Talisman of Coalescence', spell_id = 10821, ability = 'Talisman of Coalescence' },
        } },
      { id = 82665, name = 'Spell Pack: Talisman of the Cougar',
        abilities = {
          { item = 116238, item_name = 'Spell: Talisman of the Cougar', spell_id = 15238, ability = 'Talisman of the Cougar' },
        } },
      { id = 50107, name = 'Spell Pack: Wild Companions',
        abilities = {
          { item = 117581, item_name = 'Spell: Cunning Lioness Companion', spell_id = 10823, ability = 'Cunning Lioness Companion' },
          { item = 117583, item_name = 'Spell: Gray Elephant Companion', spell_id = 10824, ability = 'Gray Elephant Companion' },
          { item = 117584, item_name = 'Spell: Black Scorpion Companion', spell_id = 10829, ability = 'Black Scorpion Companion' },
          { item = 117586, item_name = 'Spell: Wooly Rhino Companion', spell_id = 10830, ability = 'Wooly Rhino Companion' },
          { item = 117587, item_name = 'Spell: Blood Raptor Companion', spell_id = 10832, ability = 'Blood Raptor Companion' },
          { item = 117591, item_name = 'Spell: Sea Cow Companion', spell_id = 10833, ability = 'Sea Cow Companion' },
        } },
    },
    singles = {
      { id = 80285, name = 'Spell: Breath of Ju\'rek', spell_id = 41232, ability = 'Breath of Shadows' },
      { id = 80288, name = 'Spell: Curse of Emoush', spell_id = 15147, ability = 'Curse of Emoush' },
      { id = 80287, name = 'Spell: Shadowy Sloth', spell_id = 15144, ability = 'Shadowy Sloth' },
      { id = 80286, name = 'Spell: Transcendental Torpor', spell_id = 15141, ability = 'Transcendental Torpor' },
    },
  },
  ['Necromancer'] = {
    packs = {
      { id = 82806, name = 'Spell Pack: Dull Agony',
        abilities = {
          { item = 78814, item_name = 'Spell: Dull Agony', spell_id = 10910, ability = 'Dull Agony' },
        } },
      { id = 82800, name = 'Spell Pack: Goner\'s Urgent Renewal',
        abilities = {
          { item = 79075, item_name = 'Spell: Goner\'s Urgent Renewal', spell_id = 10738, ability = 'Goner\'s Urgent Renewal' },
        } },
      { id = 82805, name = 'Spell Pack: Sacrilege of the Wraith',
        abilities = {
          { item = 78808, item_name = 'Spell: Sacrilege of the Wraith', spell_id = 10476, ability = 'Sacrilege of the Wraith' },
        } },
    },
    singles = {
      { id = 80786, name = 'Spell: Malignant Plague', spell_id = 15230, ability = 'Malignant Plague' },
      { id = 80785, name = 'Spell: Molten Pyre', spell_id = 15225, ability = 'Molten Pyre' },
      { id = 119599, name = 'Spell: Pestilent Pustules', spell_id = 10906, ability = 'Pestilent Pustules' },
      { id = 78819, name = 'Spell: Ritual of Blood', spell_id = 10482, ability = 'Ritual of Blood' },
      { id = 78892, name = 'Spell: Venom of the Accursed Nest', spell_id = 10555, ability = 'Venom of the Accursed Nest' },
      { id = 80784, name = 'Spell: Yearning of Death', spell_id = 15222, ability = 'Yearning of Death' },
    },
  },
  ['Wizard'] = {
    packs = {
      { id = 82795, name = 'Spell Pack: Bolster of the Sorcerer',
        abilities = {
          { item = 79110, item_name = 'Spell: Bolster of the Sorcerer', spell_id = 10773, ability = 'Bolster of the Sorcerer' },
        } },
      { id = 82797, name = 'Spell Pack: Ethereal Weave',
        abilities = {
          { item = 79107, item_name = 'Spell: Ethereal Weave', spell_id = 10861, ability = 'Ethereal Weave' },
        } },
      { id = 82796, name = 'Spell Pack: Supernal Skin',
        abilities = {
          { item = 79201, item_name = 'Spell: Supernal Skin', spell_id = 10864, ability = 'Supernal Skin' },
        } },
    },
    singles = {
      { id = 80763, name = 'Spell: Arcane Sanctuary', spell_id = 15180, ability = 'Arcane Sanctuary' },
      { id = 80760, name = 'Spell: Eruption of Telakemara', spell_id = 15167, ability = 'Eruption of Telakemara' },
      { id = 79388, name = 'Spell: Ether Blaze', spell_id = 11835, ability = 'Ether Blaze' },
      { id = 80761, name = 'Spell: Evoker\'s Pyromantic Blade', spell_id = 15168, ability = 'Evoker\'s Pyromantic Blade' },
      { id = 79129, name = 'Spell: Serenity Harvest', spell_id = 10792, ability = 'Serenity Harvest' },
      { id = 79390, name = 'Spell: Wildmagic Salvo', spell_id = 11840, ability = 'Wildmagic Salvo' },
    },
  },
  ['Magician'] = {
    packs = {
      { id = 82799, name = 'Spell Pack: Circle of Magmaskin',
        abilities = {
          { item = 79084, item_name = 'Spell: Circle of Magmaskin', spell_id = 10747, ability = 'Circle of Magmaskin' },
        } },
      { id = 82800, name = 'Spell Pack: Goner\'s Urgent Renewal',
        abilities = {
          { item = 79075, item_name = 'Spell: Goner\'s Urgent Renewal', spell_id = 10738, ability = 'Goner\'s Urgent Renewal' },
        } },
      { id = 82798, name = 'Spell Pack: Ward of the Conjurer',
        abilities = {
          { item = 78038, item_name = 'Spell: Ward of the Conjurer', spell_id = 10885, ability = 'Ward of the Conjurer' },
        } },
    },
    singles = {
      { id = 80766, name = 'Spell: Blade Rend', spell_id = 15191, ability = 'Blade Rend' },
      { id = 50144, name = 'Spell: Burning Bladestorm', spell_id = 10890, ability = 'Burning Bladestorm' },
      { id = 79091, name = 'Spell: Fickle Inferno', spell_id = 10754, ability = 'Fickle Inferno' },
      { id = 80764, name = 'Spell: Frantic Blaze', spell_id = 15182, ability = 'Frantic Blaze' },
      { id = 80779, name = 'Spell: Grant Battle Materiel', spell_id = 15192, ability = 'Grant Battle Materiel' },
      { id = 80765, name = 'Spell: Monolithic Strength', spell_id = 15188, ability = 'Monolithic Strength' },
    },
  },
  ['Enchanter'] = {
    packs = {
      { id = 82804, name = 'Spell Pack: Edict of Tashan',
        abilities = {
          { item = 115515, item_name = 'Spell: Edict of Tashan', spell_id = 14515, ability = 'Edict of Tashan' },
        } },
      { id = 82802, name = 'Spell Pack: Ellowind Hastening',
        abilities = {
          { item = 78939, item_name = 'Spell: Speed of Ellowind', spell_id = 10602, ability = 'Speed of Ellowind' },
          { item = 78996, item_name = 'Spell: Hastening of Ellowind', spell_id = 10659, ability = 'Hastening of Ellowind' },
        } },
      { id = 82801, name = 'Spell Pack: Intuition',
        abilities = {
          { item = 78954, item_name = 'Spell: Seer\'s Intuition', spell_id = 10617, ability = 'Seer\'s Intuition' },
          { item = 78999, item_name = 'Spell: Voice of Intuition', spell_id = 10662, ability = 'Voice of Intuition' },
        } },
      { id = 82803, name = 'Spell Pack: Presidio of the Seer',
        abilities = {
          { item = 78920, item_name = 'Spell: Presidio of the Seer', spell_id = 10583, ability = 'Presidio of the Seer' },
        } },
    },
    singles = {
      { id = 50149, name = 'Spell: Boon of the Sentinel', spell_id = 10902, ability = 'Boon of the Sentinel' },
      { id = 80781, name = 'Spell: Chromatic Chaos', spell_id = 15212, ability = 'Chromatic Chaos' },
      { id = 80783, name = 'Spell: Hysteria', spell_id = 15216, ability = 'Hysteria' },
      { id = 80782, name = 'Spell: Urgent Rune of Destiny', spell_id = 15213, ability = 'Urgent Rune of Destiny' },
      { id = 80780, name = 'Spell: Whispers of Emoush', spell_id = 10656, ability = 'Whispers of Emoush' },
    },
  },
  ['Beastlord'] = {
    packs = {
      { id = 82819, name = 'Spell Pack: Growl of the Mountain Puma',
        abilities = {
          { item = 115170, item_name = 'Spell: Growl of the Mountain Puma', spell_id = 14170, ability = 'Growl of the Mountain Puma' },
        } },
      { id = 82818, name = 'Spell Pack: Roaring Spirit of Tirranun',
        abilities = {
          { item = 78686, item_name = 'Spell: Roaring Spirit of Tirranun', spell_id = 10349, ability = 'Roaring Spirit of Tirranun' },
        } },
      { id = 82820, name = 'Spell Pack: Sha\'s Urgent Renewal',
        abilities = {
          { item = 115093, item_name = 'Spell: Sha\'s Urgent Renewal', spell_id = 14093, ability = 'Sha\'s Urgent Renewal' },
          { item = 115099, item_name = 'Spell: Feral Exigency', spell_id = 14099, ability = 'Feral Exigency' },
        } },
      { id = 82817, name = 'Spell Pack: Spiritual Vibrance',
        abilities = {
          { item = 78676, item_name = 'Spell: Spiritual Vibrance', spell_id = 10339, ability = 'Spiritual Vibrance' },
        } },
    },
    singles = {
      { id = 81933, name = 'Spell: Feral Mettle', spell_id = 15261, ability = 'Feral Mettle' },
      { id = 81934, name = 'Spell: Ravenous Ice', spell_id = 15263, ability = 'Ravenous Ice' },
      { id = 78701, name = 'Spell: Roaring Sleet', spell_id = 10364, ability = 'Roaring Sleet' },
      { id = 81868, name = 'Spell: Spiritual Enlightenment', spell_id = 15260, ability = 'Spiritual Enlightenment' },
      { id = 81867, name = 'Spell: Swift Salve of the Stillmoon', spell_id = 15257, ability = 'Swift Salve of the Stillmoon' },
    },
  },
  ['Berserker'] = {
    packs = {
      { id = 82657, name = 'Tome Pack: Ancient: Annihilator\'s Volley', off_vendor = true,
        abilities = {
          { item = 79450, item_name = 'Tome of Ancient: Annihilator\'s Volley', spell_id = 11928, ability = 'Ancient: Annihilator\'s Volley' },
        } },
    },
    singles = {
      { id = 79226, name = 'Tome of Arcane Reprisal', spell_id = 10889, ability = 'Arcane Reprisal' },
      { id = 59925, name = 'Tome of Battle Focus Discipline', spell_id = 15116, ability = 'Battle Focus Effect' },
      { id = 79251, name = 'Tome of Bloodcurdling Scream', spell_id = 10915, ability = 'Bloodcurdling Scream' },
      { id = 50120, name = 'Tome of Cleaving Madness Discipline', spell_id = 10860, ability = 'Cleaving Madness Discipline' },
      { id = 50118, name = 'Tome of Cry of Catastrophe', spell_id = 10857, ability = 'Cry of Catastrophe' },
      { id = 80081, name = 'Tome of Fourth Wind', spell_id = 15134, ability = 'Fourth Wind Discipline' },
      { id = 80280, name = 'Tome of Rancorous Flurry Discipline', spell_id = 15120, ability = 'Rancorous Flurry Discipline' },
      { id = 50119, name = 'Tome of Vigorous Axe Throw', spell_id = 10858, ability = 'Vigorous Axe Throw' },
      { id = 80281, name = 'Tome of Wounded Rage Discipline', spell_id = 15122, ability = 'Wounding Rage' },
    },
  },
}
