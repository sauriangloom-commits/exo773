# Rules and Lore Traceability

Each row links implemented behavior to a source. Categories:

- **Supported** — implemented within the stated scope, using the source values.
- **Interpreted** — the source is ambiguous or silent; a documented ruling was made.
- **Adapted** — intentionally changed for a computer game; original intent noted.
- **Deferred** — not implemented; must not be presented as working.

Page citations use printed pages, with PDF pages in parentheses. See
[REFERENCE_INDEX.md](REFERENCE_INDEX.md) for the +1 offset verification.

## Core rules

| # | Behavior | Implementation | Source | Type | Scope / notes |
| ---: | --- | --- | --- | --- | --- |
| 1 | Ability scores and modifiers | `src/core/rules.gd` | PHB Ch. 1, pp. 7–10 (PDF 8–11) | Supported | Standard `(score-10)/2` floor; scores fixed by pregens |
| 2 | Armor Class | `Rules.armor_class`, `Character` | PHB Ch. 8, pp. 133–137 (PDF 134–138) | Supported | Armor + shield + Dex (capped by armor) + size + natural armor; touch excludes natural armor; helpless uses Dex 0. Combat-start flat-footedness is applied; see row 2a. |
| 2a | Combat-start flat-footed | `Encounter.begin`, `Encounter.flat_footed`, `Encounter.is_flat_footed`, `Encounter._begin_turn`, `Rules.armor_class`, `Rules.touch_ac`, `Rules._feat_ac_bonus`, `Rules.attack`, `CombatScreen.effective_ac` | PHB p. 133 (PDF 134), p. 134 (PDF 135), p. 136 (PDF 137) | Supported | Every combatant starts flat-footed and remains so until the start of that combatant's first turn. The state denies a **positive** Dexterity bonus on normal and touch AC, and denies dodge bonuses with it; a Dexterity penalty still applies and a zero modifier changes nothing (p. 136: "If you don't have a Dexterity bonus, nothing happens"). It also denies attacks of opportunity and lets a rogue sneak attack the target; undead and constructs stay immune to that sneak attack. Party attacks, opportunity attacks, monster attacks, ranged touch spells and the trip touch attack all pass the state to the shared attack resolver; the enemy inspect panel reads the same `Rules.armor_class` through `CombatScreen.effective_ac` and marks the state. Awareness only determines whether a surprise round occurs. p. 134 says the state lasts "until he or she takes an action"; ending it at the start of the turn is this project's stated reading. No supported creature has uncanny dodge or Combat Reflexes, so no printed exception is currently required (see SUPPORTED_FEATURES). |
| 3 | Hit points and hit dice | `Character`, `content/characters.json` | PHB Ch. 3 class tables; Ch. 8 | Supported | Level-3 pregens with authored HP; no level-up |
| 4 | Initiative | `Encounter.begin`, `Feats.initiative_bonus` | PHB Ch. 8, p. 135 (PDF 136); Improved Initiative p. 95 | Supported | d20 + Dex + Improved Initiative (+4); ties broken deterministically for reproducibility (Interpreted) |
| 5 | Attack rolls | `Rules.attack_bonus`, `Encounter` | PHB Ch. 8, pp. 135–140 (PDF 136–141) | Supported | BAB + ability + size + misc; natural 1/20; -4 weapon non-proficiency and non-proficient armor/shield ACP included |
| 6 | Critical threats and confirmation | `Rules`, `Encounter` | PHB Ch. 8, p. 140 | Supported | Threat range/multiplier; confirmation; undead and constructs are immune |
| 7 | Saving throws | `Rules.saving_throw_bonus`, `Feats.modifier` | PHB Ch. 8 and Ch. 10; Iron Will/Lightning Reflexes/Great Fortitude pp. 94–96 | Supported | Fort/Ref/Will; class + ability + feat bonuses; ghoul paralysis uses Fort DC 12 |
| 8 | Skills and checks | `Skills`, `Rules.skill_check`, `Rules.skill_armor_check_penalty`, `GameSession` | PHB Ch. 4, pp. 61–86 (PDF 62–87); Table 4-2 p. 63; Table 4-5 p. 66 | Supported | All 45 Table 4-2 skills cataloged; ranks separate from ability, per-skill armor, feat and synergy modifiers; trained-only, take 10/20, Aid Another, opposed checks and rank caps. Only authored uses are exercised in play. |
| 8a | Feat prerequisites and typed stacking | `Feats`, `Rules.stack_bonuses` | PHB Ch. 5, pp. 87–102 (PDF 88–103); stacking p. 153 | Supported | Prerequisites re-checked on every use (temporary loss suspends the benefit); same-type bonuses take the best, same-type penalties stack, dodge stacks, circumstance stacks by source; unknown feats are content errors. |
| 8b | Implemented feats | `src/core/feats.gd`, `Rules`, `Encounter` | PHB pp. 89–102; MM p. 304 | Supported | Thirty-eight feats: Iron Will, Lightning Reflexes, Great Fortitude, Dodge (+1 general dodge; target selection adapted), Improved Initiative, Alertness, Skill Focus, Weapon Focus, Weapon Finesse, Point Blank Shot, Toughness, Multiattack, Extra Turning, Improved Turning, fourteen +2/+2 skill feats, the seven proficiency feats (Armor light/medium/heavy, Shield, Simple, Martial, Exotic), Power Attack, Combat Expertise and Combat Casting. Exotic has no shipped exotic weapon; Tower Shield is deferred. |
| 8c | Other PHB feats | — | PHB Ch. 5, Table 5-1 pp. 90–91 | Deferred | Combat actions, full attacks, cover, spell schools/resistance, item creation, mounts, advancement and wild shape are named per feat in [FEATS_SKILLS_COVERAGE.md](FEATS_SKILLS_COVERAGE.md). |
| 8d | Weapon/armor/shield proficiencies | `Character.proficiencies`, `Feats.is_weapon_proficient`, `Feats.is_armor_proficient`, `Feats.is_shield_proficient`, `Rules.weapon_nonproficiency_penalty` | PHB Ch. 7; proficiency feats pp. 89, 94, 97, 100 | Supported | Authored categories and exact items combine with prerequisite-valid feat grants. Manufactured non-proficient weapons take -4; non-proficient armor/shield ACP applies to attacks and all movement skills including Ride. `proficiency_schema` 2 migrates legacy saves once. Selection is through the existing JSON feat list, not an in-game picker. Tower Shield remains deferred. |
| 8e | Power Attack | `Feats.power_attack_max`, `Rules.attack`, `Rules.damage_bonus`, `Encounter.attack_active`, `Encounter.set_active_power_attack`, `CombatScreen` | PHB Ch. 5, p. 98 (PDF 99) | Supported for the single attack action | Strength 13; amount up to base attack bonus is committed per actor and applies to melee attacks and relevant attacks of opportunity until the start of that actor's next turn. The control locks after the standard action; switching actors preserves another actor's commitment. Light weapons gain no damage but still take the penalty; two-handed weapons gain twice; unarmed/natural attacks are the light-weapon exception. Ranged and thrown attacks do not receive it. `attack_modes` separates melee/thrown/ranged; legacy range-only data defaults ranged and ordinary weapons default melee. One-handed weapons wielded in two hands and full attacks remain deferred; no shipped two-handed weapon or shipped pregen exercises Power Attack. |
| 8f | Combat Expertise | `Feats.combat_expertise_max`, `Feats.combat_expertise_attack_penalty`, `Feats.combat_expertise_dodge_bonus`, `Rules.attack`, `Rules.armor_class`, `Rules.touch_ac`, `Encounter.set_active_combat_expertise`, `CombatScreen` | PHB Ch. 5, p. 92 (PDF 93); dodge bonuses and denied Dexterity p. 135; fighting defensively p. 139; total defense p. 141 | Supported for the single attack action | Intelligence 13; amount up to `min(5, base attack bonus)`. The control stores a pending amount that grants nothing until a qualifying melee attack; that attack takes the penalty and the committed amount then applies to later melee attacks, opportunity attacks and the character's AC until the start of their next turn. Ranged and thrown attacks discard the pending choice. The bonus is a dodge bonus, so it is lost when flat-footed or helpless and stacks with other dodge bonuses; it never adds damage. Prerequisite and cap are re-checked on every AC/attack use. Fighting defensively, total defense, full attacks and one-handed-in-two-hands are deferred; "until your next action" is read as until the start of the next turn (Interpreted). No shipped pregen exercises it. |
| 9 | Action economy | `Encounter.turn_state` | PHB Ch. 8, Actions pp. 138–149 (PDF 139–150) | Supported | One standard, one move, free actions; full-round actions deferred |
| 10 | 5-ft step | `Encounter.step` | PHB Ch. 8, p. 139 (PDF 140) | Supported | One per turn; does not provoke; cannot combine with other movement |
| 11 | Attacks of opportunity | `Encounter` AoO handling | PHB Ch. 8, pp. 137–141 | Supported | One reaction per creature per round, cleared each round; threatened movement, ranged-in-melee and potion use; not every trigger |
| 12 | Movement and adjacency | `BattleMap`, `Dungeon` | PHB Ch. 8, battle grid p. 135 | Adapted | 5-ft squares; diagonal costs 5 ft (tabletop 5-10-5) — see Adaptation Log #2 |
| 13 | Ranged attacks and range increments | `Encounter` | PHB Ch. 8, pp. 139–150 | Supported | Increment penalty; maximum range; LOS/cover deferred |
| 14 | Damage reduction | `Character.take_damage`, `Encounter` | MM Glossary p. 305 (PDF 306); Zombie p. 265 (PDF 266) | Supported | Zombie DR 5/slashing; bypass checked by damage type |
| 15 | Undead traits | `Character`, `content/monsters.json` | MM Glossary p. 305; Zombie p. 265 | Supported | No Con, destroyed at 0 HP, immune to effects that require living targets; only the subset used by content |
| 16 | Ghoul paralysis | `content/monsters.json`, `Encounter` | MM Ghoul p. 118 (PDF 119); PHB Ch. 2 for elf immunity | Supported | Fort DC 12, 1d4+1 rounds, elf immunity, once per hit |
| 17 | Zombie single actions | `Encounter` monster AI | MM Zombie p. 265 (PDF 266) | Supported | Zombies never take a full-round action; one move or attack |
| 18 | Spells | `content/spells.json`, `Encounter` | PHB Ch. 11, pp. 181+ (PDF 182+); entries p. 196+ | Supported (bounded) | Six spells only; slots tracked; components and material foci deferred. Casting interruptions and defensive casting are rows 18a and 18b. |
| 18a | Concentration during casting | `Encounter.cast_active_spell`, `Encounter._concentration_check`, `Skills`, `Rules.skill_check` | PHB p. 69 (PDF 70); Table 4-2 p. 70 (PDF 71); p. 170 (PDF 171) | Supported (bounded) | Damage taken while casting (including damage from an opportunity attack the cast itself provoked) requires a Concentration check at DC 10 + damage + spell level. Every damaging interruption gets its own check and the first failure ends the attempt (p. 70: "make a check for each one; any failed check indicates that the task is not completed"). Concentration is usable untrained with the Constitution modifier, so no trained-only gate and no free ranks are granted; no shipped caster has ranks in it, which is preserved (see ADAPTATION_LOG 40). Failure produces no spell effect and still spends the standard action, the slot and the prepared cast. Not covered: readied/delayed actions, counterspells, grappling, weather, ongoing-damage types and casting from scrolls. |
| 18c | Combat Casting | `Feats.CATALOG.combat_casting`, `Feats._condition_ok`, `Skills.feat_bonus`, `Encounter._concentration_check` | PHB p. 92 (PDF 93) | Supported (defensive clause only) | +4 untyped on Concentration checks made to cast a spell while on the defensive; the feat's second printed circumstance, casting while grappling or pinned, is not modeled and is not granted. The condition is carried in the skill-check options, so ordinary injury checks and every other Concentration use receive nothing. A non-repeatable feat's text counted once even if duplicated, while content validation still rejects the duplicate; no shipped character has the feat. |
| 19 | Weapon access in combat | `Character.carried_weapons`, `Encounter.draw_weapon`, `Encounter.sheathe_weapon`, `CombatScreen` weapon control | PHB pp. 138, 142 (PDF 139, 143) | Supported | Putting a weapon away and readying another are separate move actions ("Draw or Sheathe a Weapon", p. 142); PHB p. 138 lets a move-equivalent spend the standard action instead, so a swap can use both slots in one turn and is never cheaper than the page. The previous weapon stays carried, not dropped. The readied weapon drives attack bonus, damage, range, criticals, damage type, proficiency, feats and attack modes through the existing resolver. The free draw combined with a regular move (BAB +1) is not granted. A two-handed weapon is refused while a shield is strapped on. |
| 19a | Crossbow loading and loaded state | `content/shared/items.json` (`reload`, `hands`), `Encounter.load_weapon`, `is_weapon_loaded`, `loaded_weapons`, `attack_active` | PHB pp. 113, 115-116 (PDF 114, 116-117) | Supported (adapted persistence) | Loading a light crossbow is a move action that provokes and needs two hands; firing spends the shot, so an unloaded crossbow cannot fire and a refused shot spends nothing. The load can spend the standard action as a move (p. 138). The shot belongs to the weapon id, not to the hands: stowing a loaded crossbow and drawing it again keeps it loaded, while a spent shot is never restored by switching. Loading interrupted by incapacitation completes nothing. Bolts are a free draw, so ammunition is not tracked, and the state never enters a save. |
| 19b | Threat and opportunity attacks | `Encounter.available_melee_attack`, `threat_capability`, `_threatens_cell`, `_threatening_enemies`, `_provoke_single_opportunity`, `_provoke_attacks_of_opportunity`, `_is_flanked`, `_into_melee_penalty` | PHB pp. 133, 137, 139-140 (PDF 134, 138, 140-141) | Supported | "If you're unarmed, you don't normally threaten any squares": threat requires an armed attack - a readied weapon with a melee mode, a natural weapon, or an "armed" unarmed attack from Improved Unarmed Strike. Ordinary empty hands can attempt a strike but grant no threat, flanking, engagement or reaction. A ranged-only weapon never threatens and is never used as an improvised melee blow; an unsupported reaction is refused with a reason and consumes no reaction. Engagement for the into-melee penalty accepts either direction ("either threatens the other"), and flanking uses the same threat test. Flat-footedness stays separate: a flat-footed creature still threatens but cannot react. The monk and touch-spell clauses of p. 139 are unreachable in this content. |
| 19c | Ready or loose a shield | `Character.carried_shields`, `Encounter.ready_shield`, `loose_shield`, `CombatScreen` shield control | PHB p. 142 (PDF 143) | Supported | Strapping a carried shield on is a move action and adds its shield bonus, armor check penalty and proficiency rules through the existing AC path. Loosing is a move action that unstraps **and drops** the shield on the character's square; it is not stored in a pack. Recovery uses the existing Pick up action, so nothing is duplicated or silently created. Only one shield can be strapped at a time, and a two-handed readied weapon blocks strapping one on. |
| 19e | Fighting defensively and total defense | `Encounter.set_fight_defensively`, `fight_defensively_selected_for`, `_activate_fighting_defensively`, `total_defense`, `Rules.defensive_dodge_bonus`, `Encounter._resolve_attack`, `_provoke_attacks_of_opportunity`, `CombatScreen` stance control | PHB p. 140 (PDF 141), p. 143 (PDF 144), p. 84; RC p. 54 | Supported (bounded) | Fighting defensively is selected, not active: the choice grants nothing, can be cancelled, and can be replaced by total defense until a legal attack commits it. Only the commit point of a legal attack activates it, so a refused or cancelled attack leaves no bonus and writes no stance line. Once active it applies -4 to every attack roll for the round, including opportunity attacks, and +2 dodge AC (+3 with 5 Tumble ranks) to normal and touch AC; it cannot be cancelled and ends at the start of the character's next turn. It stacks with Combat Expertise (RC p. 54), whose bonus stays melee-only. Total defense is a standard action: +4 dodge AC (+6 with 5 Tumble ranks), no attacks and no opportunity attacks, and it refuses Combat Expertise and an active fighting-defensively stance. Dodge bonuses are lost while Dexterity is denied. Both stances and Combat Expertise are combat-scope effects: `Encounter.finish` clears them and the encounter-only selections before the resolution save, so a fight that ends mid-stance cannot leave a dodge bonus on the character or in the autosave. No shipped character has Tumble ranks, so the replacement bonus is unit-tested but unreachable in content. |
| 19d | Ammunition, bucklers, shield bash | - | PHB pp. 113, 142 | Deferred | No ammunition inventory, no buckler (free-to-loose variant), no shield bash, no dual-wielding. Two-handed melee weapons are covered only by the refusal because no shipped weapon is two-handed. |
| 18b | Casting on the defensive | `Encounter.cast_active_spell(..., {"defensive": true})`, `CombatScreen._open_spells`, `Game.combat_cast` | PHB p. 140 (PDF 141) | Supported | The spell list's per-casting checkbox trades the opportunity attack for one Concentration check at DC 15 + spell level; failure loses the spell (action and slot spent) and success casts normally. The mode is chosen explicitly for one cast, resets every time the list opens, and never leaks between characters, turns or encounters. Combat Casting's +4 bonus is not implemented (FEATS_SKILLS_COVERAGE). |
| 19 | Conditions and durations | `Character`, `Encounter` | PHB Ch. 8 and spell descriptions | Supported (bounded) | Round-based expiry; bless/mage armor/aid/paralysis/dying/stable/dead; other stacking rules deferred |
| 20 | Dying and stabilization | `Character`, `Encounter._begin_turn` | PHB Ch. 8, pp. 133–160 | Supported | 0 to −9 dying, 10% stabilize per round, −10 dead; stabilization by Heal DC 15 |
| 21 | Equipment and inventory | `Character`, `Panels.inventory`, content | PHB Ch. 7, pp. 111–132 (PDF 112–133) | Supported (bounded) | Weapons, armor, shields, consumables; encumbrance and item weight ignored (Adapted) |
| 22 | XP | `GameSession` victory/effects | DMG/PHB encounter rewards | Adapted | XP is awarded and saved, but there is no level-up or wealth-by-level system |
| 23 | Rest and recovery | `GameSession.rest_party` | No exact tabletop analogue | Adapted | Shrine fully restores HP and spell slots as a deliberate recovery point |
| 24 | Flanking / sneak attack | `Encounter` | PHB Ch. 8; Rogue class features; flat-footed p. 133 | Interpreted | Flanking requires two enemies that actually threaten the target (row 19b) on opposite axes; no facing-based flanking. A helpless or flat-footed target is sneak-attackable as well (row 2a); undead and constructs are immune, matching 3.5. |
| 25 | Ranged line of sight | `BattleMap.has_line_of_sight`, `Encounter` | PHB Ch. 8, ranged combat | Supported | Bresenham LOS; blocked cells stop movement, attacks and spells. Cover/concealment remain deferred |
| 25a | Shooting or throwing into a melee | `Encounter._into_melee_penalty`, `Encounter._resolve_attack`, `Encounter._cast_scorching_ray`, `Rules.attack` (`into_melee_penalty`), `Feats.CATALOG.precise_shot` | PHB p. 140 (PDF 141); Precise Shot p. 98 (PDF 99); Point Blank Shot p. 98; Complete Arcane pp. 73, 85 | Supported | -4 on the attack roll when the target is engaged in melee with a friendly character. Engagement uses the printed definition (they are enemies of each other and either threatens the other); a target at least 10 ft. from the nearest friendly character is exempt even while engaged; Precise Shot removes the penalty and its prerequisite is enforced. Applies to ranged and thrown weapons and to ranged touch spells as weaponlike spells. Helpless targets count as not engaged, a bounded reading of "unless he is actually being attacked" because the slice does not track who was attacked this round. Soft cover from creatures is modelled (row 25b); wall cover and concealment are not. Window-verified in candidate `ranged_windowed_2026-11-13` (`--ranged-probe`, 49 checks): -4 on an engaged target, none on an unengaged one, none with Precise Shot. |
| 25b | Soft cover from creatures on ranged attacks | `BattleMap.cells_crossed`, `BattleMap.creature_cover`, `Encounter.creature_cover`, `Encounter._resolve_attack`, `Encounter._cast_scorching_ray`, `Rules.attack` (`cover`), `Rules.format_attack`, `CombatScreen.effective_ac`, `CombatScreen.cover_summary`, `CombatScreen._cover_vs_active` | PHB p. 151 (PDF 152); Soft Cover p. 152 (PDF 153); touch attacks, Rules Compendium; Complete Arcane p. 85 | Supported | A creature whose square lies on the line gives the target +4 AC against ranged, thrown and ranged touch attacks. The grid applies the printed method: every one of the attacker's four corners is tried, and cover exists only when each corner still has a line to a corner of the target's square that crosses another creature (`cells_crossed`), so one clear corner means no cover and a centre-to-centre line is not used. Two creatures do not stack. Cover applies to normal and touch AC because touch attacks keep every modifier except armor, shield and natural armor. The encounter computes the term once; the roll, the log and the inspect panel read the same value, and the panel names the shooter and states both the normal and touch AC. Grid adaptations: only interior crossings count, walls stay with line of sight and reach melee is excluded (ADAPTATION_LOG 19d-19f), and no supported creature is Large, so the melee-only big-creature clause is unreachable. Precise Shot does not remove cover; Improved Precise Shot (BAB +11) is outside this content. Windowed fixture `--demo-cover --cover-probe` asserts the rendered clause, its wrapping and fit, and normal/touch AC parity at 100 % and 160 % (candidate `creature_cover_inspector_2026-11-21`). |
| 25b | Ranged attack while threatened | `Encounter.attack_active`, `Encounter.cast_active_spell`, `Encounter._threatening_enemies` | PHB p. 135 (PDF 136) | Supported | One attack of opportunity per threatening opponent, resolved before the attack. Separate from 25a: a threatened attacker can shoot an unengaged target, and an unthreatened attacker can shoot an engaged one. A ray provokes once for the casting and adds no second reaction for firing; the windowed probe asserts that no creature reacts twice. Window-verified in candidate `ranged_windowed_2026-11-13`. |
| 26 | Grapple, disarm, sunder, bull rush; NPC-initiated or mounted trip | — | PHB Ch. 8 special attacks | Deferred | Player-initiated Trip against NPCs is supported and export-verified; these remain unsupported |
| 27 | Player iterative/full attacks, TWF | — | PHB Ch. 8 | Deferred | Player has one attack per attack action; multiattack monsters use their full natural-attack routine |
| 28 | Turn undead: check, damage, destruction | `Encounter.turn_undead`, `Rules.turn_max_hd`, `Rules.turn_damage`, `Feats.extra_turning_uses`, `Feats.turn_level_bonus` | PHB Ch. 8, "Turn or Rebuke Undead", pp. 159–160 (PDF 160–161); Cleric class p. 33; Extra Turning p. 94; Improved Turning p. 96 | Supported | Standard action, no AoO, requires a present holy symbol, 3 + Cha + 4 per Extra Turning uses/day; d20 + Cha (Table 8-9) caps effective Hit Dice; 2d6 + effective cleric level + Cha is total effective Hit Dice; closest first, 60 ft, line of effect; destroyed when the effective cleric level is at least twice the creature's effective Hit Dice. Improved Turning adds +1 effective level to all three level-based clauses. +2 with 5 ranks of Knowledge (religion). |
| 28a | Turned undead behavior and duration | `Encounter._run_turned_turn`, `Encounter._check_turning_approach`, `Character` conditions | PHB p. 159, "Effect and Duration of Turning" | Supported | Flee for 10 rounds by the best legal route within one move action; cower (+2 to attacks against them) when no route increases the distance. The effect ends when the cleric that turned the creature moves from beyond 10 ft to within 10 ft — standing within 10 ft, another ally approaching, or the turned creature approaching do **not** break it. Turning never ends an encounter by itself. |
| 28b | Turn resistance | `Character.turn_effective_hd`, `content/monsters.json` | MM Ghoul p. 119 (PDF 120); MM Glossary, "Turn Resistance", p. 317 (PDF 318) | Supported | Added to Hit Dice for the turning attempt: maximum-HD eligibility, capacity spent and the destruction comparison. Authored per creature: ghoul +2 (2 HD, treated as 4), drowned dead 0, E3 infected zombie 0 (the ECR Strahd zombie has no turn resistance). Applying it to the destruction clause is an interpretation of "Hit Dice total" for the attempt; the stricter reading is used. |
| 28c | Rebuke/command/bolster undead, dispelling turning | — | PHB pp. 159–160 | Deferred | Evil-cleric paths and dispelling are outside this milestone; do not claim support |
| 29 | Readied/delayed actions | — | PHB Ch. 8 | Deferred | Not exposed in the UI |
| 30 | Encumbrance | — | PHB Ch. 9, pp. 161–162 | Deferred | Carrying Capacity table read but not enforced |
| 31 | Level advancement | — | PHB Ch. 3 | Deferred | Pregens remain level 3; XP is a progress indicator only |

## Exploration and presentation

| # | Behavior | Implementation | Source | Type | Notes |
| ---: | --- | --- | --- | --- | --- |
| 32 | Grid exploration and facing | `Dungeon`, `GameSession`, `FirstPersonView` | PHB battle-grid convention p. 135 | Adapted | 5-ft cells for exploration; four cardinal facings; raycaster is presentation only |
| 33 | Doors, objects, triggers | `Dungeon`, `GameSession.interact` | Original design; ECR presentation | Adapted | Locked crypt door uses Open Lock DC 15 and a key item |
| 34 | Search checks and one-time loot | `GameSession`, `content/dungeon.json` | PHB Ch. 4 Search | Supported | Best party skill used; success removes the object and sets a flag; take 10/20 offered in exploration |
| 35 | DM narration | `content/narration.json`, log panel | ECR DM-facing presentation | Adapted | Original placeholder prose, clearly labelled |
| 36 | NPC and creature dialogue | `DialogueRunner`, `content/dialogue/` | Original framework; ECR tone and E3 | Adapted | Speaker kinds npc/creature/narrator/party; Ashlyn is source-adapted, the gatehouse characters remain invented |
| 37 | Conditional choices and skill checks | `DialogueRunner`, `GameSession.check_conditions` | PHB Ch. 4 skill checks | Supported | Check actor defaults to best conscious party member; can be pinned by id; checks accept take 10/20 and a circumstance modifier |
| 38 | Quest persistence | `QuestLog`, `content/quests.json` | Original design; ECR E3 lead | Adapted | Drowned Bell (four objectives), Lightbringers (two objectives), Ashwick Ferry (five) and Lantern Watch (three). Completion is a one-time session transition: later flag synchronizations do not re-announce an already complete quest (2026-11-13 correction). |
| 39 | Dialogue consequences | `GameSession.apply_effects` | Original design | Adapted | Flags, items, gold, XP, narration, quest start, combat start, doors, rest, travel |
| 40 | Save/load and continuation | `SaveSystem`, `GameSession` | Project design, not tabletop | Adapted | Versioned JSON; active area, per-area doors/loot/searched/visited, RNG, flags, party, position and quests restored |
| 41 | Autosave | `GameSession` | Project design | Adapted | After dialogue ends and after combat victory, in exploration only |
| 42 | Defeat and recovery | `Main`, `GameSession` | Project design | Adapted | Defeat screen offers load/restart; no silently erased progress |

## Lore

| # | Element | Source | Type | Notes |
| ---: | --- | --- | --- | --- |
| 43 | Ravenloft tone (mist, fear, undead, isolated village) | ECR Ch. 1–2, printed pp. 5–47 | Adapted | Tone and presentation only |
| 44 | Strahd as distant background presence | ECR Ch. 1, pp. 5–18 | Referenced only | Not a character in the slice; no canonical event depicted |
| 45 | Village of Barovia | ECR Ch. 2, area E3, p. 25 (PDF 26); tactical p. 36–37 (PDF 37–38) | Supported (bounded) | 11×11 town-square excerpt only; church, full village and later campaign deferred |
| 46 | The Old Gatehouse / Miruna / Corvin / The Drowned Bell | — | Original | Invented example content, explicitly non-canon; East Gate is a developer staging map |
| 47 | Ghoul and standard zombie statistics | MM pp. 118, 265; Multiattack p. 304 | Supported (subset) | Stat-block adaptation, not copied prose; the ghoul's Multiattack is computed by the rules from its secondary attacks |
| 48 | E3 town square, breached eastern barricade, well, mercantile/tavern | ECR Ch. 2 E3, p. 25; tactical pp. 36–37 | Adapted | Bounded 11×11 excerpt; cover/hardness and building interiors deferred |
| 49 | Ashlyn, Lightbringer paladin; Thendrick, Mathilda, church lead, Madam Eva, Sunsword | ECR Ch. 2 E3, pp. 25, 36 | Adapted | NPC/dialogue only; exact CR 6 stat block, ally AI, spells and later quests deferred |
| 50 | Infected zombies in E3 | ECR tactical E3, p. 36 | Adapted | 42 hp including Toughness (39 base + 3), AC 16, slam +6 (1d6+4), DR 5/slashing, plodding; two instead of nine; disease/entomb deferred |
| 51 | Area registry, travel and per-area persistence | Project design | Adapted | Manifest, stable ids, walkable arrivals, per-area dungeon state, shared campaign flags |

## Unsupported claims

The project does **not** implement the complete D&D 3.5 ruleset, the Ravenloft
campaign setting, or *Expedition to Castle Ravenloft*. Anything not listed as
Supported above should be treated as Deferred. The UI labels unsupported choices
or explains why an action is unavailable rather than silently accepting input.

### Trip and prone (player-initiated Trip integrated)

| Rule | Source | Implementation | Tests |
| --- | --- | --- | --- |
| Trip sequence, size limit, opposed check, counter-trip | PHB pp. 158-159 | `Encounter.trip_active` | `test_trip.gd` |
| Trip weapons, no opportunity attack, weapon release | PHB p. 159 | `trip` item data, `Encounter._drop_weapon` | `test_trip.gd` |
| Prone attack modifiers | PHB Table 8-5, p. 151 | `Rules.attack_bonus`, `Rules.prone_ranged_attack_allowed` | `test_prone_and_size.gd` |
| Prone AC modifiers | PHB Table 8-6, p. 151 | `Rules.prone_ac_modifier`, `Rules.armor_class`, `Rules.touch_ac` | `test_prone_and_size.gd` |
| Standing up | PHB pp. 143, 159 | `Encounter.stand_up_active` | `test_trip.gd` |
| Opposed-check ties | PHB p. 64 | `Rules.opposed_ability_check` | `test_prone_and_size.gd` |
| Size categories and modifiers | PHB glossary p. 312 | `Rules.SIZE_CATEGORIES`, `Character.size_category` | `test_prone_and_size.gd` |
| Improved Trip prerequisites (INT 13, Combat Expertise) | PHB p. 96 | `Feats.CATALOG.improved_trip`, `Feats.prereqs` | `test_improved_trip.gd` |
| Improved Trip +4 on the attacker's trip check only | PHB p. 96 | `Feats.improved_trip_check_bonus`, `Encounter.trip_active` | `test_improved_trip.gd` |
| No opportunity attack for an unarmed trip with the feat | PHB pp. 96, 158 | `Encounter.trip_active` | `test_improved_trip.gd` |
| Immediate follow-up attack, player-chosen melee attack, decline, no recursion | PHB p. 96 | `Encounter.resolve_improved_trip_attack`, `_improved_trip_weapon`, `CombatScreen._rebuild_decision` | `test_improved_trip.gd` |
| Cleave prerequisites (STR 13, Power Attack) | PHB p. 92 | `Feats.CATALOG.cleave`, `Feats.prereqs`, `Feats.cleave_available` | `test_cleave.gd` |
| Cleave trigger: a party member's resolved melee attack (own or off turn) drops a creature, another enemy in reach | PHB p. 92 | `Encounter._resolve_attack` -> `_offer_cleave`, `cleave_targets` | `test_cleave.gd`, `test_cleave_offturn.gd` |
| Opportunity attacks are melee attacks and can trigger Cleave; the attacker identity, not the active combatant, owns the decision | PHB pp. 92, 137 | `Encounter._provoke_attacks_of_opportunity`, `pending_cleave["off_turn"]` | `test_cleave_offturn.gd` |
| Off-turn Cleave never takes the turn; the interrupted route resumes through a bounded record | PHB pp. 92, 137, 159; engine safety | `Encounter.off_turn_resume`, `resume_interrupted`, `GameSession._resume_after_cleave` | `test_cleave_offturn.gd` |
| Cleave attack: same weapon and the attack's own base, target modifiers re-evaluated, no extra action, no 5-ft step | PHB p. 92 | `Encounter.resolve_cleave_attack`, `Rules.attack` (`force_attack_base`, `bonus_base`) | `test_cleave.gd`, `test_cleave_offturn.gd` |
| Cleave once per round across own and off-turn uses, no chaining, reset at round start | PHB p. 92 | `Encounter.cleave_used`, cleared in `_begin_round` | `test_cleave.gd`, `test_cleave_offturn.gd` |
| Cleave decision boundary, decline, duplicate submission, invalidated target | PHB p. 92; engine safety | `Encounter.decline_cleave`, `has_pending_decision`, `CombatScreen._rebuild_decision` | `test_cleave.gd`, `test_cleave_offturn.gd`, `test_trip_pending_guards.gd` |
| Training entry: "Combat Training / Rules Demonstrations" is separate from campaign saves and XP | Project scope | `Game.training_mode`, `Main._show_training_menu`, `Main._start_training` | `test_cleave_offturn.gd`, `--training-probe` |
| Command-line demonstrations never autosave over player slots or grant campaign XP | Project scope | `Main._start_demo` sets `Game.training_mode`, `GameSession._resolve_encounter` | `--training-probe`, demo probes |
| Effects and conditions are one registry, not per-layer lists | Engine safety | `ContentSpec.EFFECTS`/`CONDITIONS`, `ContentDB._validate_effect_list`, `GameSession.apply_effects`/`check_conditions` | `test_extensibility.gd` |
| Authored effects/conditions validate required fields, field kinds and item/quest/encounter/area/skill references | Engine safety | `ContentSpec.validate_effect`, `validate_condition`, `validate_effect_list` | `test_extensibility.gd` |
| Qualified or conditional modifiers are evaluated where the roll happens, not copied from a stored total | PHB pp. 134, 153; engine safety | `Feats.modifier`, `Rules.attack` (`bonus_base`), `Rules.armor_class` | `test_cleave_offturn.gd`, `test_feats_skills.gd` |

| Pending-decision boundary | PHB p. 159; engine safety | `Encounter._pending_guard`, `GameSession.equip_item`/`use_item` | `test_trip_pending_guards.gd` |
| Ground item, pickup cost, victory recovery | PHB pp. 141, 144 | `Encounter.ground_items`, `pick_up_active`, `GameSession._resolve_encounter` | `test_trip` and `test_trip_pending_guards.gd` |
| Prone crawl, 5-ft step refused | PHB p. 142 | `Encounter.move_active_to` | `test_trip.gd` |
| Combat-screen controls and labels | — | `CombatScreen` Trip/Stand up/Pick up, decision panel, ground list | windowed probe in source and export |

These rows describe the implemented player-initiated paths. The player-as-defender
counter-trip prompt is unreachable because NPCs never initiate Trip. Improved Trip
is supported for the player-initiated path; mounted trip and non-listed trip
weapons remain deferred.

Cleave is supported for a party member's resolved melee attack on or off turn,
including Improved Trip's granted follow-up and opportunity attacks, with the
interrupted turn resumed afterwards. Interpretation recorded: the source's "same
bonus" preserves the attack's own base and committed attack-mode context, not a
final total that already included target-specific circumstances (helpless,
cowering, flanking, prone, reach); those are re-evaluated against the new target.
Unsupported and explicitly deferred: Great Cleave (needs a repeatable attack
chain and its own verification), ranged/spell/damage-over-time triggers, NPC
attackers taking Cleave, and any interaction with a full-attack/iterative chain
(none exists).

## Ordinary unarmed attacks (2026-11-13)

| Behavior | Source | Implementation | Evidence |
| --- | --- | --- | --- |
| An empty-handed character can still attempt a melee attack | PHB p. 139 | `Encounter.available_melee_attack`, `_unarmed_strike` | `test_unarmed_attack.gd`, `--unarmed-probe` |
| Unarmed strike damage is nonlethal and size-based (1d3 Medium, 1d2 Small, 1d4 Large) | PHB p. 139 | `Encounter._unarmed_strike`, `Character.nonlethal`, `apply_nonlethal` | `test_unarmed_attack.gd`, `--unarmed-probe` |
| Attacking unarmed provokes from the armed target, not from unarmed foes | PHB p. 139 | `Encounter.attack_active` provocation block | `test_unarmed_attack.gd`, `--unarmed-probe` |
| Undead and constructs take no nonlethal damage | MM traits; PHB p. 139 | `Rules.nonlethal_immune`, `_apply_damage` nonlethal branch | `test_unarmed_attack.gd`, `--unarmed-probe` |
| Nonlethal damage is tracked apart from hit points and is persisted | PHB pp. 139, 145 | `Character.nonlethal`, `to_dict`/`from_dict`, `CombatScreen` labels | `test_unarmed_attack.gd` |
| Threat stays with the armed state, never with empty hands | PHB p. 137 | `Encounter.threat_capability` (unchanged by this unit) | `test_melee_threat.gd` |

Lethal unarmed strikes are supported: Improved Unarmed Strike (PHB p. 97) lets
the attacker choose lethal or nonlethal damage at no penalty, and a character
without the feat may choose lethal at the printed −4 (PHB p. 147). Not
implemented: monk unarmed damage (a class feature, not the feat), touch-spell
delivery, natural hourly nonlethal recovery (rest clears the total instead), and
a dedicated nonlethal-recovery action beyond magical healing.

## Nonlethal conditions and healing (2026-11-13)

| Behavior | Source | Implementation | Evidence |
| --- | --- | --- | --- |
| Nonlethal damage is a separate running total, never deducted from hit points | PHB p. 147 | `Character.nonlethal`, `apply_nonlethal` | `test_nonlethal_state.gd` |
| Nonlethal equal to current hit points is staggered (one standard or one move action per round) | PHB p. 147 | `Character.nonlethal_state`, `refresh_nonlethal_state`, `Encounter._staggered_blocks_*`, `CombatScreen._can_standard` | `test_nonlethal_state.gd`, `--nonlethal-probe` |
| Nonlethal above current hit points is unconscious and helpless | PHB pp. 147, 153 | `nonlethal_unconscious` effect, `Rules.is_helpless` | `test_nonlethal_state.gd`, `--nonlethal-probe` |
| Losing hit points can cross either threshold; healing can retreat back over it | PHB p. 147 | `take_damage` / `heal` / `apply_nonlethal` refresh the derived state | `test_nonlethal_state.gd` |
| Zero nonlethal damage never staggers a character at 0 hit points | PHB pp. 145, 147 | `nonlethal_state` short-circuits at a zero total | `test_nonlethal_state.gd` |
| Clearing nonlethal never erases another incapacity | Engine safety | separate effect ids for `staggered` and `nonlethal_unconscious` | `test_nonlethal_state.gd` |
| Magical healing removes nonlethal damage equal to the amount it cures | PHB p. 147 | `Character.magical_heal`; cure spell, potions, authored healing effect | `test_nonlethal_state.gd`, `--nonlethal-probe` |
| An encounter ends once no enemy can act | PHB p. 147 | `Encounter._check_end` uses `can_act()` for enemies | `test_nonlethal_state.gd`, `--nonlethal-probe` |
| Improved Unarmed Strike: armed, no provocation, lethal or nonlethal at option | PHB p. 97 | `Feats.has_feat`, `Encounter.attack_active`, unarmed damage control | `test_unarmed_attack.gd`, `test_nonlethal_state.gd` |

Adaptations: the lethal choice is a per-attack control in the combat screen and a
parameter on `attack_active`; a character without the feat takes −4 on that
attack. Monk damage progression, touch-spell delivery and natural hourly
nonlethal recovery remain outside this slice.
 The undead-immunity probe applies
damage through the same engine call the attack uses; the living-target path is
exercised through the ordinary UI.


## Bull rush (player-initiated, 2026-11-21)

| Behaviour | Source | Implementation | Evidence |
| --- | --- | --- | --- |
| Bull rush is a standard action; the charge form is not implemented | PHB p. 154 | `Encounter.bull_rush_active` spends `turn_state["standard_used"]` on declaration; `Game.combat_bull_rush` and the `Bull rush` control call it | `tests/test_bull_rush.gd` |
| The entry into the defender's space provokes from threatening opponents, including the defender; Improved Bull Rush is deferred | PHB p. 154 | `_provoke_single_opportunity(target, ch)` after the entry log, before the opposed check | `test_the_defender_makes_an_opportunity_attack_on_entry`, `test_an_opportunity_attack_that_drops_the_rusher_ends_the_push` |
| An opponent up to one size category larger can be rushed | PHB p. 154 | `Rules.size_category_steps` gate with a named refusal | `test_a_defender_two_size_categories_larger_is_refused` |
| Opposed Strength checks, ±4 per size step from Medium, defender +4 when exceptionally stable | PHB p. 154 | `Rules.opposed_ability_check` with `4 * steps` bonuses and `Character.stability_bonus` | `test_size_modifiers_are_four_per_category_from_medium`, `test_a_stable_defender_adds_four` |
| A win pushes 5 ft plus 5 ft per full 5 points of excess, capped by the rusher's movement | PHB p. 154 | `Encounter.bull_rush_active` push chain plus budget cap | `test_extra_push_is_five_feet_per_five_points`, `test_the_follow_is_capped_by_remaining_movement` |
| Moving with the defender is the rusher's choice and pauses resolution | PHB p. 154 | `pending_bull_rush` (`type: follow`) with `resolve_bull_rush_decision(follow)` and the Push 5 ft / Follow buttons | `test_declining_the_follow_pushes_only_five_feet`, `test_following_pushes_the_full_distance_and_moves_the_rusher` |
| The two participants never provoke from each other for this movement | PHB p. 154 | `_provoke_attacks_of_opportunity(..., except_index)` excludes the other participant | `test_a_won_check_pushes_five_feet_and_takes_the_square` (log), engine guard |
| A lost check sends the rusher 5 ft back, prone there if the square is occupied | PHB p. 154 | `bull_rush_active` loss branch | `test_a_lost_check_costs_the_action_and_leaves_the_rusher_where_he_stood`, `test_a_lost_check_falls_prone_when_the_starting_square_is_occupied` |

Adaptations: the blocked-square stop, the no-space refusal, the entry costing
movement and the grid-diagonal direction are recorded in `ADAPTATION_LOG.md`
19i-19j, not presented as printed rules. Excluded: the charge form, Improved Bull
Rush, the 25 % redirect for third-party reactions, mounted bull rush, AI use,
multi-square creatures and terrain effects.
