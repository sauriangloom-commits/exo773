# Reference Index

This index covers the reference library used for the vertical slice. It records
what was actually inspected, how page numbers map, and where extraction is
unreliable. It does **not** reproduce rules text or adventure prose.

## Library location and scope

- Folders inspected historically: the Downloads library listed in the old path;
  current private library location: `workspace/references/dnd35` (workspace root);
  verified extraction: `workspace/references/extractions/phb_skills_feats.txt`.
- Contents: **43 PDFs**, all labelled *AD&D 3.5 Edition* by their metadata.
- No separate notes files (TXT/MD/DOC/etc.) were present in that folder. The
  requested "online notes" were therefore not available as a local source; the
  index covers the PDFs only. Online material was not used as authority.
- Page counts below come from pypdf; metadata titles come from the PDFs where
  present, otherwise from the filename.

## Page-number convention (important)

Citations in this project use **printed page numbers** and give the corresponding
**PDF viewer page** where they differ.

For the three core books used in depth, the PDF page is consistently **printed
page + 1** in the sampled ranges:

| Book | Sample | Printed page shown in page footer | PDF page |
| --- | --- | --- | --- |
| Player's Handbook | Combat Basics | 135 | 136 |
| Monster Manual I | Table of Contents | 3 | 4 |
| Expedition to Castle Ravenloft | Village of Barovia | 29 | 30 |

The offset comes from the cover/front matter. A PDF viewer that counts the cover
differently can shift by one; always use the printed footer when cross-checking.
Page ranges below are from the printed table of contents.

## Primary sources used for rules and lore

### Player's Handbook (3.5)

`Wizards of the Coast - AD&D 3.5 Edition - Player's Handbook.pdf`
325 PDF pages. Mechanical baseline for this project.

| Section | Printed pages | PDF pages | Used for |
| --- | --- | --- | --- |
| Ch. 1: Abilities | 7–10 | 8–11 | Ability scores, modifiers, checks |
| Ch. 2: Races | 11–20 | 12–21 | Elf immunity to ghoul paralysis, racial basics |
| Ch. 3: Classes | 21–60 | 22–61 | Pregenerated class/HD/save/spell baselines |
| Ch. 4: Skills | 61–86 | 62–87 | Skill checks, DCs, Search/Sense Motive/Diplomacy/Intimidate/Heal/Open Lock |
| Ch. 5: Feats | 87–102 | 88–103 | Only feats already on the pregens (e.g. weapon focus) |
| Ch. 7: Equipment | 111–132 | 112–133 | Weapons, armor, shields, gear, potions |
| Ch. 8: Combat | 133–160 | 134–161 | Initiative, AC, attacks, actions, movement, AoOs, damage, dying |
| — Combat Basics | 135 | 136 | Confirmed battle grid and initiative text |
| — Actions in Combat | 138 | 139 | Standard/move/full/free actions and 5-ft step |
| — Combat Modifiers | 150 | 151 | Ranged/melee modifiers, flanking, cover (cover deferred) |
| Ch. 9: Adventuring | 161–168 | 162–169 | Carrying capacity (not enforced), exploration conventions |
| Ch. 10: Magic | 169–180 | 170–181 | Spellcasting, saving throws, caster level |
| Ch. 11: Spells | 181+ | 182+ | The six implemented spell descriptions (entries begin p. 196) |

### Monster Manual I (3.5)

`Wizards of the Coast - AD&D 3.5 Edition - Monster Manual I.pdf`
322 PDF pages. Monster statistics and undead/DR behavior.

| Section | Printed page | PDF page | Used for |
| --- | --- | --- | --- |
| Ghoul entry | 118 | 119 | Paralysis DC 12, 1d4+1 rounds; bite/claw; undead traits |
| Zombie entry | 265 | 266 | 2d12+3 HP, AC 11, slam +2 (1d6+1), DR 5/slashing, single actions |
| Glossary: undead type | 305 | 306 | Undead traits, destroyed at 0 HP, no Constitution |
| Glossary: damage reduction | 305 | 306 | DR notation and bypass rules |

The ghoul and zombie stat blocks in `content/monsters.json` are adaptations of
these entries, not verbatim copies. The ghast entry was read for context only and
is not implemented.

### Expedition to Castle Ravenloft (3.5)

`Wizards of the Coast - AD&D 3.5 Edition - Expedition to Castle Ravenloft.pdf`
223 PDF pages. Primary adventure-specific reference for tone, presentation and
undead/village context.

| Section | Printed page | PDF page | Used for |
| --- | --- | --- | --- |
| Ch. 1: Adventures in Ravenloft | 5 | 6 | Ravenloft tone, Strahd as background presence |
| Ch. 2: Village of Barovia | 23 | 24 | Village tone, frightened villagers, undead pressure |
| — sampled village text | 29 | 30 | Confirmed chapter layout and page offset |
| — E3: Zombies in Town Square | 25 | 26 | First-square encounter, breached eastern barricade, Ashlyn and follow-up |
| — E3 tactical encounter | 36–37 | 37–38 | Infected-zombie/Ashlyn statistics, barricade/well/business features |
| Ch. 3: Lands of Barovia | 48 | 49 | Geography reference only; not reproduced |
| Ch. 4: Castle Ravenloft | 90 | 91 | Castle atmosphere reference only; not reproduced |

**Bounded source use:** the E3 town square is a small adapted excerpt; the
encounter is reduced. The Old Gatehouse, Miruna, Corvin, The Drowned Bell and the
East Gate staging map are original demo content. The full village, church,
Madam Eva, Sunsword and campaign are not implemented. Expedition to Castle
Ravenloft is an adventure, not a setting bible; no Ravenloft Campaign Setting
book is present in the library.

### Dungeon Master's Guide (3.5)

`Wizards of the Coast - AD&D 3.5 Edition - Dungeon Master's Guide.pdf`
324 PDF pages. Consulted lightly for DC conventions, encounter presentation and
treasure expectations. No page-specific rules claim in this project depends on
the DMG; the PHB/MM entries above are authoritative for implemented mechanics.

## Complete library inventory

"Used" means read for this implementation. "Library" means present and indexed but
not used as a rules authority for the slice.

| # | File (without folder) | Pages | Status |
| ---: | --- | ---: | --- |
| 1 | Book of Exalted Deeds | 195 | Library |
| 2 | Character Sheets | 4 | Library |
| 3 | Cityscape | 162 | Library |
| 4 | Complete Adventurer | 207 | Library |
| 5 | Complete Arcane | 207 | Library |
| 6 | Complete Champion | 171 | Library |
| 7 | Complete Divine | 208 | Library |
| 8 | Complete Mage | 162 | Library |
| 9 | Complete Psionic | 160 | Library |
| 10 | Complete Scoundrel | 160 | Library |
| 11 | Complete Warrior | 175 | Library |
| 12 | Draconomicon: The Book of Dragons | 290 | Library |
| 13 | Dragon Magic | 162 | Library |
| 14 | Drow of the Underdark | 227 | Library |
| 15 | Dungeon Master's Guide | 324 | Light use |
| 16 | Dungeon Survival Guide | 66 | Library |
| 17 | Dungeonscape | 166 | Library |
| 18 | Elder Evils | 162 | Library |
| 19 | Exemplars of Evil | 162 | Library |
| 20 | Expedition to Castle Ravenloft | 223 | Used |
| 21 | Fiendish Codex I: Hordes of the Abyss | 162 | Library |
| 22 | Fiendish Codex II: Tyrants of the Nine Hells | 162 | Library |
| 23 | Frostburn | 227 | Library |
| 24 | Heroes of Battle | 162 | Library |
| 25 | Heroes of Horror | 162 | Library |
| 26 | Libris Mortis | 196 | Library |
| 27 | Lords of Madness: The Book of Aberrations | 224 | Library |
| 28 | Magic of Incarnum | 223 | Library |
| 29 | Miniatures Handbook | 194 | Library |
| 30 | Monster Manual I | 322 | Used |
| 31 | Player's Handbook II | 224 | Library |
| 32 | Player's Handbook | 325 | Used |
| 33 | Races of Destiny | 194 | Library |
| 34 | Races of Stone | 194 | Library |
| 35 | Races of the Dragon | 160 | Library |
| 36 | Races of the Wild | 194 | Library |
| 37 | Rules Compendium | 162 | Library (not used to override PHB) |
| 38 | Sandstorm | 226 | Library |
| 39 | Stormwrack: Mastering the Perils of Wind and Wave | 223 | Library |
| 40 | Tome of Battle: The Book of Nine Swords | 176 | Library |
| 41 | Tome of Magic | 303 | Library |
| 42 | Unearthed Arcana | 226 | Library |
| 43 | Weapons of Legacy | 223 | Library |

All filenames are prefixed `Wizards of the Coast - AD&D 3.5 Edition - ` in the
folder; the prefix is omitted above for readability.

## Extraction limitations and conflicts

- **Text layer quality:** pypdf extracted the consulted core pages reliably, but
  reported missing `fontTools` for some Type1 fonts. Ligatures (ﬁ/ﬂ), curly
  quotes and soft hyphens appear as replacement characters. This affected prose
  reading, not the numerical stat blocks used.
- **Image-only pages:** *Player's Handbook II* pages 2–8 produced no text; it was
  not used. Some other splatbook TOCs are scans without a text layer. No OCR was
  required for the three core books.
- **CLI failure:** `pdftotext` could not open files in this folder through the
  available Windows/MSYS path handling; pypdf was used instead. This is recorded
  so future extraction attempts do not repeat the dead end.
- **Edition:** the library is 3.5 throughout. The folder label says "AD&D 3.5",
  which is a naming convention, not AD&D 2nd Edition. No edition mixing was done.
- **Conflicts:** where *Player's Handbook II* or *Rules Compendium* restate core
  material, the core *Player's Handbook* was treated as the baseline. No
  Ravenloft Campaign Setting source is present, so setting-wide lore claims were
  avoided and the demonstration uses a neutral invented location.
- **Copyright:** the PDFs and any extracted text remain private project material.
  They are not uploaded, committed or shipped with the game.
