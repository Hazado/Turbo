-- ============================================================================
-- DoN spell/tome/pack import queries for the TurboGear BiS catalog.
-- Target: EQEmu schema (MySQL/MariaDB). Vendor merchantid = 2089271.
--
-- Ownership model these feed:
--   entry owned = pack item held
--                 OR every ability satisfied (its scroll held OR spell/disc scribed)
--   Templates / bags summoned by packs are NOT ownership evidence; they feed
--   the glyph recipe view (references/don_glyph_recipes.lua) instead.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- A) Standalone Spell: / Song: / Tome items on the vendor -> the ability they
--    teach. item_id goes in ids{}, ability + spell_id go in the known-check.
--    s.name is the CANONICAL ability name - use it, never string-strip items.
-- ----------------------------------------------------------------------------
SELECT ml.item     AS item_id,
       i.Name      AS item_name,
       s.id        AS spell_id,
       s.name      AS ability,
       i.classes   AS class_mask
FROM merchantlist ml
JOIN items i      ON i.id = ml.item
JOIN spells_new s ON s.id = i.scrolleffect
WHERE ml.merchantid = 2089271
  AND i.scrolleffect > 0
ORDER BY i.Name;


-- ----------------------------------------------------------------------------
-- B) Pack contents straight from the DB. Each pack's clickeffect is the
--    "Open Spell Bundle" spell; its SPA 32 effect slots hold summoned item ids.
--    One row per (pack, summoned item).
-- ----------------------------------------------------------------------------
SELECT p.id    AS pack_id,
       p.Name  AS pack_name,
       p.classes AS class_mask,
       sp.id   AS bundle_spell_id,
       sp.name AS bundle_name,
       slots.n AS effect_slot,
       CASE slots.n
         WHEN 1  THEN sp.effect_base_value1  WHEN 2  THEN sp.effect_base_value2
         WHEN 3  THEN sp.effect_base_value3  WHEN 4  THEN sp.effect_base_value4
         WHEN 5  THEN sp.effect_base_value5  WHEN 6  THEN sp.effect_base_value6
         WHEN 7  THEN sp.effect_base_value7  WHEN 8  THEN sp.effect_base_value8
         WHEN 9  THEN sp.effect_base_value9  WHEN 10 THEN sp.effect_base_value10
         WHEN 11 THEN sp.effect_base_value11 WHEN 12 THEN sp.effect_base_value12
       END AS content_item_id
FROM merchantlist ml
JOIN items p       ON p.id = ml.item
JOIN spells_new sp ON sp.id = p.clickeffect
JOIN (SELECT 1 n UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) slots
WHERE ml.merchantid = 2089271
  AND (p.Name LIKE 'Spell Pack:%' OR p.Name LIKE 'Tome Pack:%')
  AND CASE slots.n
        WHEN 1  THEN sp.effectid1  WHEN 2  THEN sp.effectid2
        WHEN 3  THEN sp.effectid3  WHEN 4  THEN sp.effectid4
        WHEN 5  THEN sp.effectid5  WHEN 6  THEN sp.effectid6
        WHEN 7  THEN sp.effectid7  WHEN 8  THEN sp.effectid8
        WHEN 9  THEN sp.effectid9  WHEN 10 THEN sp.effectid10
        WHEN 11 THEN sp.effectid11 WHEN 12 THEN sp.effectid12
      END = 32
ORDER BY p.Name, slots.n;


-- ----------------------------------------------------------------------------
-- C) THE IMPORT TABLE. Query B resolved + classified.
--    kind='scroll'          -> abilities{} entry: {item_id, spell_id, ability}
--    kind='template/other'  -> exclude from ownership; template ids should match
--                              references/don_glyph_recipes.lua components.
-- ----------------------------------------------------------------------------
SELECT c.pack_id, c.pack_name, c.class_mask,
       ci.id   AS content_item_id,
       ci.Name AS content_item_name,
       ab.id   AS spell_id,
       ab.name AS ability,
       CASE WHEN ab.id IS NULL THEN 'template/other' ELSE 'scroll' END AS kind
FROM (
    SELECT p.id AS pack_id, p.Name AS pack_name, p.classes AS class_mask,
           CASE slots.n
             WHEN 1  THEN sp.effect_base_value1  WHEN 2  THEN sp.effect_base_value2
             WHEN 3  THEN sp.effect_base_value3  WHEN 4  THEN sp.effect_base_value4
             WHEN 5  THEN sp.effect_base_value5  WHEN 6  THEN sp.effect_base_value6
             WHEN 7  THEN sp.effect_base_value7  WHEN 8  THEN sp.effect_base_value8
             WHEN 9  THEN sp.effect_base_value9  WHEN 10 THEN sp.effect_base_value10
             WHEN 11 THEN sp.effect_base_value11 WHEN 12 THEN sp.effect_base_value12
           END AS content_item_id
    FROM merchantlist ml
    JOIN items p       ON p.id = ml.item
    JOIN spells_new sp ON sp.id = p.clickeffect
    JOIN (SELECT 1 n UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8
          UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) slots
    WHERE ml.merchantid = 2089271
      AND (p.Name LIKE 'Spell Pack:%' OR p.Name LIKE 'Tome Pack:%')
      AND CASE slots.n
            WHEN 1  THEN sp.effectid1  WHEN 2  THEN sp.effectid2
            WHEN 3  THEN sp.effectid3  WHEN 4  THEN sp.effectid4
            WHEN 5  THEN sp.effectid5  WHEN 6  THEN sp.effectid6
            WHEN 7  THEN sp.effectid7  WHEN 8  THEN sp.effectid8
            WHEN 9  THEN sp.effectid9  WHEN 10 THEN sp.effectid10
            WHEN 11 THEN sp.effectid11 WHEN 12 THEN sp.effectid12
          END = 32
) c
JOIN items ci      ON ci.id = c.content_item_id
LEFT JOIN spells_new ab ON ab.id = ci.scrolleffect AND ci.scrolleffect > 0
ORDER BY c.pack_name, kind DESC, ci.Name;


-- ----------------------------------------------------------------------------
-- D) Sanity checks. Run before trusting the import.
-- ----------------------------------------------------------------------------

-- D1) Packs whose click spell did NOT resolve (should be zero rows; any hit
--     means that pack opens via a server script, not SPA 32, and needs the
--     manual sheet as fallback).
SELECT p.id, p.Name, p.clickeffect
FROM merchantlist ml
JOIN items p ON p.id = ml.item
LEFT JOIN spells_new sp ON sp.id = p.clickeffect
WHERE ml.merchantid = 2089271
  AND (p.Name LIKE 'Spell Pack:%' OR p.Name LIKE 'Tome Pack:%')
  AND sp.id IS NULL;

-- D2) Scroll count per pack (compare against the sheet: most packs 1,
--     Allegiance 3, Stillmoon/Spiritoaks/Clumped Moss/Intuition/Ellowind 2,
--     Wild Companions 6, Flame and Frost 2, Cantata 2, Sha's 2).
SELECT c.pack_name, COUNT(*) AS scroll_count
FROM (
    -- same subquery as C
    SELECT p.Name AS pack_name,
           CASE slots.n
             WHEN 1  THEN sp.effect_base_value1  WHEN 2  THEN sp.effect_base_value2
             WHEN 3  THEN sp.effect_base_value3  WHEN 4  THEN sp.effect_base_value4
             WHEN 5  THEN sp.effect_base_value5  WHEN 6  THEN sp.effect_base_value6
             WHEN 7  THEN sp.effect_base_value7  WHEN 8  THEN sp.effect_base_value8
             WHEN 9  THEN sp.effect_base_value9  WHEN 10 THEN sp.effect_base_value10
             WHEN 11 THEN sp.effect_base_value11 WHEN 12 THEN sp.effect_base_value12
           END AS content_item_id
    FROM merchantlist ml
    JOIN items p       ON p.id = ml.item
    JOIN spells_new sp ON sp.id = p.clickeffect
    JOIN (SELECT 1 n UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8
          UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) slots
    WHERE ml.merchantid = 2089271
      AND (p.Name LIKE 'Spell Pack:%' OR p.Name LIKE 'Tome Pack:%')
      AND CASE slots.n
            WHEN 1  THEN sp.effectid1  WHEN 2  THEN sp.effectid2
            WHEN 3  THEN sp.effectid3  WHEN 4  THEN sp.effectid4
            WHEN 5  THEN sp.effectid5  WHEN 6  THEN sp.effectid6
            WHEN 7  THEN sp.effectid7  WHEN 8  THEN sp.effectid8
            WHEN 9  THEN sp.effectid9  WHEN 10 THEN sp.effectid10
            WHEN 11 THEN sp.effectid11 WHEN 12 THEN sp.effectid12
          END = 32
) c
JOIN items ci ON ci.id = c.content_item_id
WHERE ci.scrolleffect > 0
GROUP BY c.pack_name
ORDER BY scroll_count DESC, c.pack_name;

-- D3) Cross-check: templates found inside packs should match the glyph recipe
--     components (Mnemonic/Imbued Template items).
SELECT DISTINCT ci.id, ci.Name
FROM (
    SELECT sp2.id AS spid FROM merchantlist ml2
    JOIN items p2 ON p2.id = ml2.item
    JOIN spells_new sp2 ON sp2.id = p2.clickeffect
    WHERE ml2.merchantid = 2089271
      AND (p2.Name LIKE 'Spell Pack:%' OR p2.Name LIKE 'Tome Pack:%')
) packs
JOIN spells_new sp ON sp.id = packs.spid
JOIN (SELECT 1 n UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) slots
  ON CASE slots.n
       WHEN 1  THEN sp.effectid1  WHEN 2  THEN sp.effectid2
       WHEN 3  THEN sp.effectid3  WHEN 4  THEN sp.effectid4
       WHEN 5  THEN sp.effectid5  WHEN 6  THEN sp.effectid6
       WHEN 7  THEN sp.effectid7  WHEN 8  THEN sp.effectid8
       WHEN 9  THEN sp.effectid9  WHEN 10 THEN sp.effectid10
       WHEN 11 THEN sp.effectid11 WHEN 12 THEN sp.effectid12
     END = 32
JOIN items ci ON ci.id = CASE slots.n
       WHEN 1  THEN sp.effect_base_value1  WHEN 2  THEN sp.effect_base_value2
       WHEN 3  THEN sp.effect_base_value3  WHEN 4  THEN sp.effect_base_value4
       WHEN 5  THEN sp.effect_base_value5  WHEN 6  THEN sp.effect_base_value6
       WHEN 7  THEN sp.effect_base_value7  WHEN 8  THEN sp.effect_base_value8
       WHEN 9  THEN sp.effect_base_value9  WHEN 10 THEN sp.effect_base_value10
       WHEN 11 THEN sp.effect_base_value11 WHEN 12 THEN sp.effect_base_value12
     END
WHERE ci.Name LIKE '%Template:%'
ORDER BY ci.Name;
