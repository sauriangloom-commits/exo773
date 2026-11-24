# Feats and Skills Coverage Manifest

Source: *Player's Handbook* (3.5), Chapter 4 (skills, printed pp. 61–86) and
Chapter 5 (feats, printed pp. 87–102); *Monster Manual* p. 304 for Multiattack.
Printed page = PDF page − 1. The verified extraction used for this manifest is
`workspace/references/extractions/phb_skills_feats.txt`.

This file is the authoritative inventory. The individual feat queue is **paused**:
the current objective is the shared foundation, and the implemented feats are
kept as verified examples of the extension patterns, not as a target count. Each
future row should be classified first — A data-only, B small handler, C new
subsystem, or D unsupported/adapted — using the table in
[AUTHORING_GUIDE.md](AUTHORING_GUIDE.md#extending-shared-systems-extension-contracts).
A row marked **Deferred** is not a
player option, even if its name appears in old notes. `Feats.CATALOG` contains
only implemented feats; an unknown feat in content is a validation error.
`Skills.CATALOG` contains all 45 Table 4-2 skills, but a catalog entry does not
by itself prove that a world subsystem (swimming, crafting, tracking) exists.

Status values:

- **Integrated and verified** — engine + content + focused tests.
- **Implemented but not fully verified** — code exists, but at least one required
  verification path is missing.
- **Partially supported** — the shared check math works, but the authored world
  does not yet offer the full use.
- **Cataloged** — inventoried only; not selectable or applied.
- **Deferred because of a named dependency** — blocked on a subsystem listed in
  the row.

## Shared engine delivered in batches 1–6

| Capability | Implementation | Verification |
| --- | --- | --- |
| Typed/conditional modifiers, same-type stacking, dodge and circumstance rules | `Rules.stack_bonuses`, `Feats.modifier` | `test_typed_bonuses_stack_by_type_dodge_and_circumstance` |
| Prerequisite evaluation with player-facing reasons; temporary loss suspends the feat | `Feats.prereqs`, `Feats.has_active` | Dodge/DEX, Weapon Focus/BAB/proficiency, unknown feat tests |
| Parameterised selections and repeat selections | `Feats.parse`, `Skill Focus (skill)`, `Weapon Focus (weapon)`, repeatable Toughness and Extra Turning | Skill Focus, Weapon Focus, Toughness, Extra Turning tests |
| Ranks kept separate from totals; trained-only restrictions | `Skills.CATALOG`, `Skills.total`, `Skills.check` | Table 4-2, trained-only, rank-cap tests |
| Armor/equipment check penalties, including Swim ×2 | `Skills.breakdown`, `Rules.skill_armor_check_penalty` | Kaelen climb breakdown; per-skill and Ride tests |
| Proficiency grants and non-proficiency penalties | `Feats.granted_proficiencies`, `Rules.weapon_nonproficiency_penalty`, `Rules.armor_attack_penalty` | Weapon/armor/shield positive, negative, stacking and legacy-save tests |
| Turning feat resources and effective level | `Feats.extra_turning_uses`, `Feats.turn_level_bonus`, `Character.turn_undead_max_uses`, `Encounter.turn_undead` | Uses stacking, non-turner rejection, 3-HD vs 4-HD ghoul, damage and save tests |
| Power Attack committed attack/damage trade | `Feats.power_attack_max`, `Rules.attack`, `Rules.damage_bonus`, `Encounter.attack_active`, `CombatScreen` | BAB cap, committed duration and AOO, per-actor expiry, light/two-handed/unarmed/natural damage, ranged and thrown exclusion, explicit weapon modes, UI path and save test |
| Combat Expertise committed attack/dodge trade | `Feats.combat_expertise_max`, `Feats.combat_expertise_dodge_bonus`, `Rules.armor_class`, `Rules.touch_ac`, `Rules.attack`, `Encounter.set_active_combat_expertise`, `CombatScreen` | INT 13 and cap tests, pending-versus-committed timing, ranged discard, dodge AC on normal and touch AC, flat-footed/helpless loss, stacking with Dodge, opportunity attack, next-turn expiry, Power Attack combination, per-actor state, combat-end cleanup, UI path and save test |
| Conditional synergies (Table 4-5) | `Skills.SYNERGIES`, `Skills.synergy_bonus` | Search→Survival (tracking), Knowledge (religion)→turning |
| Take 10 / take 20 with threat and failure-penalty restrictions | `Skills.check`, `Rules.ability_check`, `GameSession.interact_with_take` | Take 10/20 tests, crate integration |
| Aid Another and opposed checks with tie handling | `Skills.aid_another`, `Skills.opposed_check` | Aid and opposed tests |
| Class/cross-class rank caps | `Skills.max_ranks`, `Skills.ranks_legal` | Rank-cap test |
| Inspectable passive breakdown and feat rows | `Skills.breakdown_text`, `Feats.describe`, character sheet | UI construction test |
| Fourteen no-prerequisite +2/+2 skill feats | `Feats.CATALOG`; two untyped `skill:<id>` modifiers each | Skill-feat catalog, exact-pair, stacking and validation tests |

Known adaptations: Dodge is a general +1 dodge bonus rather than against one
selected opponent; Toughness is applied once when a character enters play;
secondary natural attacks are penalised by `Rules.attack_bonus`, not authored
into monster data. Power Attack is a committed per-character choice in the
combat screen: one amount up to the current base attack bonus applies to the
character's melee attacks and opportunity attacks until the start of their next
turn, then expires. Ranged and thrown attacks do not receive it. Weapon
`attack_modes` distinguish melee from thrown/projectile attacks; legacy
range-only data is ranged-only and ordinary weapons default to melee. Light
weapons gain no damage; two-handed doubling is supported by metadata, but
one-handed weapons wielded in two hands and full attacks are not. Combat
Expertise separates a pending UI choice from a committed effect: the pending
amount grants nothing until a qualifying melee attack, ranged and thrown attacks
discard it, and the committed amount lasts until the start of the character's
next turn, covering later melee attacks, opportunity attacks and defense. Its
dodge bonus is lost when flat-footed or helpless. Fighting defensively and total
defense are not implemented, so their interaction is deferred. See
`ADAPTATION_LOG.md`.

## Skills (Table 4-2, complete)

Armor column is the multiplier applied to the armor check penalty. “Trained”
means ranks are required before any check is allowed.

| ID | Skill | Ability | Trained only | Armor | Status | Notes / dependency |
| --- | --- | --- | --- | --- | --- | --- |
| `appraise` | Appraise | Int | No | — | Cataloged | No appraisal subsystem |
| `balance` | Balance | Dex | No | ×1 | Partially supported | Tumble synergy; no balance encounter |
| `bluff` | Bluff | Cha | No | — | Partially supported | Dialogue engine can resolve it; no authored bluff branch |
| `climb` | Climb | Str | No | ×1 | Partially supported | Totals and armor verified; no climbing traversal |
| `concentration` | Concentration | Con | No | — | Supported | Injury while casting (DC 10 + damage + spell level, one check per interruption) and casting on the defensive (DC 15 + spell level); no shipped caster has ranks, so they use the Constitution modifier |
| `craft` | Craft | Int | No | — | Cataloged | Crafting and downtime deferred |
| `decipher_script` | Decipher Script | Int | Yes | — | Cataloged | No decipher interaction |
| `diplomacy` | Diplomacy | Cha | No | — | Integrated and verified | Dialogue checks; Bluff/Sense Motive/Knowledge (nobility) synergies |
| `disable_device` | Disable Device | Int | Yes | — | Partially supported | Check math and trained-only verified; traps deferred |
| `disguise` | Disguise | Cha | No | — | Cataloged | No disguise subsystem |
| `escape_artist` | Escape Artist | Dex | No | ×1 | Cataloged | Grapple/binding subsystem deferred |
| `forgery` | Forgery | Int | No | — | Cataloged | No document subsystem |
| `gather_information` | Gather Information | Cha | No | — | Cataloged | No rumor subsystem |
| `handle_animal` | Handle Animal | Cha | Yes | — | Cataloged | No animal handling |
| `heal` | Heal | Wis | No | — | Integrated and verified | First aid/stabilization in combat |
| `hide` | Hide | Dex | No | ×1 | Partially supported | Totals/size verified; stealth subsystem deferred |
| `intimidate` | Intimidate | Cha | No | — | Partially supported | Dialogue framework; no authored intimidation |
| `jump` | Jump | Str | No | ×1 | Cataloged | Movement does not consume a Jump check |
| `knowledge_arcana` | Knowledge (arcana) | Int | Yes | — | Partially supported | Spellcraft synergy only |
| `knowledge_architecture` | Knowledge (architecture and engineering) | Int | Yes | — | Partially supported | Search (secret doors) synergy only |
| `knowledge_dungeoneering` | Knowledge (dungeoneering) | Int | Yes | — | Partially supported | Survival (underground) synergy only |
| `knowledge_geography` | Knowledge (geography) | Int | Yes | — | Partially supported | Survival (lost/hazards) synergy only |
| `knowledge_history` | Knowledge (history) | Int | Yes | — | Cataloged | No lore-check content |
| `knowledge_local` | Knowledge (local) | Int | Yes | — | Partially supported | Gather Information synergy only |
| `knowledge_nature` | Knowledge (nature) | Int | Yes | — | Partially supported | Survival (aboveground) synergy only |
| `knowledge_nobility` | Knowledge (nobility and royalty) | Int | Yes | — | Partially supported | Diplomacy synergy only |
| `knowledge_religion` | Knowledge (religion) | Int | Yes | — | Integrated and verified | +2 turning check at 5 ranks, wired through the synergy table |
| `knowledge_planes` | Knowledge (the planes) | Int | Yes | — | Partially supported | Survival (other planes) synergy only |
| `listen` | Listen | Wis | No | — | Partially supported | Totals and Alertness verified; no passive detection loop |
| `move_silently` | Move Silently | Dex | No | ×1 | Partially supported | Totals/armor verified; no stealth subsystem |
| `open_lock` | Open Lock | Dex | Yes | — | Integrated and verified | Crypt door; take 10/20 available |
| `perform` | Perform | Cha | No | — | Cataloged | No performance subsystem |
| `profession` | Profession | Wis | Yes | — | Cataloged | Downtime subsystem deferred |
| `ride` | Ride | Dex | No | — | Cataloged | Mounted combat deferred |
| `search` | Search | Int | No | — | Integrated and verified | Crate/bier checks, take 10/20, tracking synergy |
| `sense_motive` | Sense Motive | Wis | No | — | Integrated and verified | Miruna dialogue check |
| `sleight_of_hand` | Sleight of Hand | Dex | Yes | ×1 | Cataloged | No pickpocket subsystem |
| `speak_language` | Speak Language | — | Yes | — | Cataloged | No language tracking (not a check) |
| `spellcraft` | Spellcraft | Int | Yes | — | Partially supported | Synergies only; no identify/counterspell |
| `spot` | Spot | Wis | No | — | Partially supported | Totals and Alertness verified; no passive detection loop |
| `survival` | Survival | Wis | No | — | Partially supported | Tracking synergy; no tracking/travel subsystem |
| `swim` | Swim | Str | No | ×2 | Cataloged | No swimming traversal |
| `tumble` | Tumble | Dex | Yes | ×1 | Partially supported | Synergies only; no tumble-through-threat |
| `use_magic_device` | Use Magic Device | Cha | Yes | — | Cataloged | No UMD item activation |
| `use_rope` | Use Rope | Dex | No | — | Cataloged | No rope/binding subsystem |

### Skill authoring notes

- `skill_ranks` stores ranks only. Never author a total.
- `Skills.check` returns `available: false` with a reason for unknown,
  trained-only-without-ranks, non-check, blocked-retry and invalid-take cases.
  Do not expose a disabled option as if it were usable.
- Dialogue checks accept optional `take` (10/20) and `circumstance` (integer).
  Exploration offers take 10/20 on the object or door ahead.
- Armor check penalties are calculated from equipped armor and shield; the
  catalog decides whether a skill is affected and whether it is doubled (Swim).

## Feats (Table 5-1, complete)

Legend for the dependency column: **none** means the current engine could
implement the feat in a later batch without a new subsystem; otherwise the
blocking subsystem is named. Implemented feats have their own tests.

Batch 2 printed-page citations (PDF page = printed page + 1): Acrobatic, Agile,
Animal Affinity and Athletic p. 89; Deceitful, Deft Hands and Diligent p. 93;
Investigator and Magical Aptitude p. 97; Negotiator, Nimble Fingers and
Persuasive p. 98; Self-Sufficient p. 100; Stealthy p. 101.
Batch 3 citations: Armor Proficiency p. 89; Exotic Weapon Proficiency p. 94;
Martial Weapon Proficiency p. 97; Shield Proficiency and Simple Weapon
Proficiency p. 100. Tower Shield Proficiency p. 101 is deferred.
Batch 4 citations: Extra Turning p. 94; Improved Turning p. 96.
Batch 5 citation: Power Attack p. 98.
Batch 6 citation: Combat Expertise p. 92; dodge bonuses and denied Dexterity
p. 135; fighting defensively p. 139; total defense p. 141 (read for the deferred
interactions only).

### General feats

| Feat | Prerequisites | Benefit | Status | Dependency / next step |
| --- | --- | --- | --- | --- |
| Acrobatic | — | +2 Jump and Tumble | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Agile | — | +2 Balance and Escape Artist | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Alertness | — | +2 Listen and Spot | Integrated and verified | `Feats.CATALOG`; typed skill modifiers |
| Animal Affinity | — | +2 Handle Animal and Ride | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Armor Proficiency (light) | — | Wear light armor without the non-proficiency attack/ACP penalty | Integrated and verified | `armor_category: light_armor`; normal ACP still affects skills (PHB p. 89) |
| Armor Proficiency (medium) | Armor Proficiency (light) | Wear medium armor without the non-proficiency penalty | Integrated and verified | Requires the light feat; normal ACP affects skills (p. 89) |
| Armor Proficiency (heavy) | Armor Proficiency (light), Armor Proficiency (medium) | Wear heavy armor without the non-proficiency penalty | Integrated and verified | Requires light + medium; normal ACP affects skills (p. 89) |
| Athletic | — | +2 Climb and Swim | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Augment Summoning | Spell Focus (conjuration) | Summoned creatures gain +4 Str/Con | Deferred | summoning and Spell Focus subsystems |
| Blind-Fight | — | Reroll concealment miss chance | Deferred | concealment/miss-chance subsystem |
| Combat Casting | — | +4 Concentration when casting defensively | Supported (defensive clause) | +4 untyped on defensive-casting checks only; the printed grappling/pinned clause is not modeled and is not granted |
| Combat Expertise | Int 13 | Trade up to 5 points of melee attack bonus for an equal dodge bonus to AC | Integrated and verified for the supported single attack action | `Feats.combat_expertise_max` + `Rules.attack`/`armor_class`/`touch_ac`; pending choice grants nothing until a legal melee attack, then the committed amount applies to that attack and lasts until the actor's next turn; ranged/thrown attacks discard it; dodge AC is lost when flat-footed or helpless; fighting defensively, total defense and full attacks deferred |
| Improved Disarm | Combat Expertise | +4 disarm; no AoO | Deferred | disarm special attack |
| Improved Feint | Combat Expertise | Feint as a move action | Deferred | feint action |
| Improved Trip | Combat Expertise | +4 trip; no AoO | Integrated and verified for the supported single attack action | `Feats.CATALOG` + `improved_trip_check_bonus`; +4 on the attacker's trip check only, no unarmed provoke, and one immediate follow-up attack after a successful trip, offered as a take/decline decision. The follow-up is any melee attack already in hand — the equipped weapon's legal melee mode or an unarmed strike — chosen at the decision; ranged modes are refused and nothing is drawn or equipped; no second standard action, no iterative chain; monk bonus-feat exception and feat selection deferred |
| Whirlwind Attack | Dex 13, Combat Expertise, Dodge, Mobility, Spring Attack, BAB +4 | Melee attack against each opponent in reach | Deferred | multi-target full attack and prerequisite feats |
| Combat Reflexes | — | Additional attacks of opportunity | Deferred | variable AoO allowance |
| Deceitful | — | +2 Disguise and Forgery | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Deft Hands | — | +2 Sleight of Hand and Use Rope | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Diligent | — | +2 Appraise and Decipher Script | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Dodge | Dex 13 | +1 dodge bonus to AC against a selected target | Integrated and verified | Applied generally; target selection deferred (adaptation) |
| Mobility | Dodge | +4 dodge AC against some AoOs | Deferred | AoO trigger classification |
| Spring Attack | Mobility, BAB +4 | Move before and after a melee attack | Deferred | split movement + full attack action |
| Endurance | — | +4 vs nonlethal damage | Deferred | nonlethal damage/fatigue subsystem |
| Diehard | Endurance | Remain conscious at −1 to −9 hp | Deferred | dying-state variant |
| Eschew Materials | — | Cast without material components | Deferred | spell components |
| Exotic Weapon Proficiency | BAB +1; Str 13 for bastard sword or dwarven waraxe | No -4 penalty with the selected exotic weapon | Implemented but not fully verified | Selection and penalty removal tested with a synthetic exotic weapon; no exotic weapon is authored in shipped content |
| Extra Turning | Ability to turn/rebuke undead | +4 turning uses per day; repeatable and stacking | Integrated and verified | `Feats.extra_turning_uses`; 4 → 8 → 12 uses tested (p. 94) |
| Great Fortitude | — | +2 Fortitude saves | Integrated and verified | `Feats.CATALOG`; saves |
| Improved Counterspell | — | Counterspell with same-school spell | Deferred | counterspell subsystem |
| Improved Critical | Proficient, BAB +8 | Double threat range | Deferred | per-weapon threat modification |
| Improved Initiative | — | +4 initiative | Integrated and verified | `Encounter.begin` |
| Improved Turning | Ability to turn/rebuke undead | +1 effective cleric level for turning | Integrated and verified | `Feats.turn_level_bonus`; cap, damage and destruction use the effective level (p. 96) |
| Improved Unarmed Strike | — | Armed while unarmed, no provocation against armed foes, lethal or nonlethal damage at will (no damage die change; PHB p. 97) | Supported | `test_unarmed_attack.gd`, `test_nonlethal_state.gd`, `--unarmed-probe` |
| Improved Grapple | Dex 13, Improved Unarmed Strike | +4 grapple; no AoO | Hooks implemented, not selectable | Both effects are live through `Feats.has_feat("improved_grapple")` in `Encounter._grapple_bonus` and the grapple reaction gate, and `test_grapple.gd` authors the raw feat text. The feat is not in `Feats.CATALOG` because Improved Unarmed Strike is not there either, so it cannot be chosen at level-up; adding the chain is batch 8e |
| Deflect Arrows | Dex 13, Improved Unarmed Strike | Deflect one ranged attack/round | Deferred | reaction/ranged defence subsystem |
| Snatch Arrows | Dex 15, Deflect Arrows, Improved Unarmed Strike | Catch a deflected arrow | Deferred | Deflect Arrows |
| Stunning Fist | Dex 13, Wis 13, Improved Unarmed Strike, BAB +8 | Stun with unarmed strike | Deferred | unarmed strike and stunning condition |
| Investigator | — | +2 Gather Information and Search | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Iron Will | — | +2 Will saves | Integrated and verified | `Feats.CATALOG`; saves |
| Leadership | Character level 6 | Cohort and followers | Deferred | level advancement and follower subsystem |
| Lightning Reflexes | — | +2 Reflex saves | Integrated and verified | `Feats.CATALOG`; saves |
| Magical Aptitude | — | +2 Spellcraft and Use Magic Device | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Martial Weapon Proficiency | — | No -4 penalty with the selected martial weapon | Integrated and verified | `Name (weapon)` JSON authoring hook; the selection does not leak to other weapons (p. 97) |
| Mounted Combat | Ride 1 rank | Negate hits on mount with Ride | Deferred | mounted combat |
| Mounted Archery | Mounted Combat | Half ranged penalty while mounted | Deferred | mounted combat |
| Ride-By Attack | Mounted Combat | Move before/after mounted charge | Deferred | mounted combat |
| Spirited Charge | Mounted Combat, Ride-By Attack | Double damage on mounted charge | Deferred | mounted combat |
| Trample | Mounted Combat | Target cannot avoid mounted overrun | Deferred | mounted combat and overrun |
| Natural Spell | Wis 13, wild shape | Cast while wild shaped | Deferred | druid wild shape |
| Negotiator | — | +2 Diplomacy and Sense Motive | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Nimble Fingers | — | +2 Disable Device and Open Lock | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Persuasive | — | +2 Bluff and Intimidate | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Point Blank Shot | — | +1 ranged attack/damage within 30 ft | Integrated and verified | `Rules.attack_bonus`/`damage_bonus` |
| Far Shot | Point Blank Shot | Increase range increment | Deferred | per-attack range-increment modification |
| Precise Shot | Point Blank Shot | No −4 for shooting into melee (and for a ranged spell fired into a melee, Complete Arcane p. 73) | Integrated and verified | `Encounter._into_melee_penalty`, `Feats.CATALOG.precise_shot`; no passive modifier, the exemption is the whole effect |
| Rapid Shot | Dex 13, Point Blank Shot | Extra ranged attack each round | Deferred | full-attack action |
| Manyshot | Dex 17, Point Blank Shot, Rapid Shot, BAB +6 | Two or more arrows at once | Deferred | full-attack/volley subsystem |
| Shot on the Run | Dex 13, Dodge, Mobility, Point Blank Shot, BAB +4 | Move before/after ranged attack | Deferred | split movement |
| Improved Precise Shot | Dex 19, Point Blank Shot, Precise Shot, BAB +11 | Ignore less than total cover/concealment | Deferred | cover/concealment |
| Power Attack | Str 13 | Trade up to base attack bonus from melee attacks for equal damage until next turn | Integrated and verified for the supported single attack action | `Feats.power_attack_max` + `Rules.attack`/`damage_bonus`; committed per actor and persists through relevant opportunity attacks; expires at next turn and cannot change after the attack roll; light weapons gain no damage, two-handed doubles, unarmed/natural exception; ranged/thrown excluded; explicit attack modes; one-handed-in-two-hands and full attack deferred |
| Cleave | Power Attack | Extra melee attack after dropping a target | Integrated and verified for own-turn and off-turn (opportunity-attack) triggers | `Feats.cleave_available` + `Encounter._offer_cleave`/`resolve_cleave_attack`; one extra melee attack with the same weapon after any party member's resolved melee attack drops a living enemy, offered as a take/decline decision listing only living enemies in reach; the attack's own base is kept and target-specific modifiers (helpless, cowering, flanking, prone, reach) are re-evaluated for the new target; off-turn triggers resume the interrupted action through a bounded resume record instead of taking the turn; once per round across own and off-turn uses, cleared at round start, no movement or 5-ft step, no chaining from the granted attack; ranged/spell/DoT triggers and NPC attackers unsupported; Great Cleave and the full-attack chain deferred |
| Great Cleave | Cleave, Power Attack, BAB +4 | No limit to cleave attacks | Deferred | Cleave is implemented for one extra attack per round; Great Cleave needs a repeatable attack-chain implementation and its own source/verification work. Iterative attacks are a separate deferral, not a prerequisite this engine requires (there is no full-attack action yet) |
| Improved Bull Rush | Power Attack | +4 bull rush; no AoO | Deferred, now unblocked (2026-11-21) | The bull rush special attack landed for the player-initiated path, so only the feat itself remains; it needs the +4 bonus on the rush check and the removal of the defender's provoked attack |
| Improved Overrun | Power Attack | +4 overrun; no AoO | Deferred | overrun special attack |
| Improved Sunder | Power Attack | +4 sunder; no AoO | Deferred | sunder special attack |
| Quick Draw | BAB +1 | Draw weapon as a free action | Deferred | weapon-drawing action economy |
| Rapid Reload | Crossbow proficiency | Reload crossbow faster | Deferred | reload action economy |
| Run | — | Run 5× speed; +4 running Jump | Cataloged | none; movement mode extension |
| Self-Sufficient | — | +2 Heal and Survival | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Shield Proficiency | — | Use existing shields without the non-proficiency penalty | Integrated and verified | `proficiency: shield`; normal shield ACP remains (p. 100) |
| Improved Shield Bash | Shield Proficiency | Keep shield AC when bashing | Deferred | shield bash attack |
| Tower Shield Proficiency | Shield Proficiency | Use tower shields; -10 ACP and cover rules | Deferred | Named dependency: no tower shield item or cover/total-cover mechanic |
| Simple Weapon Proficiency | — | No -4 non-proficiency penalty with simple weapons | Integrated and verified | Category `simple`; attack penalty path verified |
| Skill Focus | — | +3 with selected skill | Integrated and verified | parameterised selection; repeatable for new skills |
| Spell Focus | — | +1 save DC for a school | Deferred | spell save DC/school metadata |
| Greater Spell Focus | Spell Focus | +1 save DC for a school | Deferred | Spell Focus |
| Spell Mastery | Wizard level 1 | Prepare some spells without spellbook | Deferred | spellbook/preparation subsystem |
| Spell Penetration | — | +2 caster level vs spell resistance | Deferred | spell resistance |
| Greater Spell Penetration | Spell Penetration | +4 caster level vs spell resistance | Deferred | spell resistance |
| Stealthy | — | +2 Hide and Move Silently | Integrated and verified | `Feats.CATALOG`; untyped +2 to both printed skills |
| Toughness | — | +3 hit points | Integrated and verified | repeatable; applied once on entry |
| Track | — | Use Survival to track | Deferred | tracking subsystem |
| Two-Weapon Fighting | Dex 15 | Reduce two-weapon penalties | Deferred | two-weapon fighting |
| Two-Weapon Defense | Two-Weapon Fighting | +1 shield bonus with off-hand weapon | Deferred | two-weapon fighting |
| Improved Two-Weapon Fighting | Dex 17, Two-Weapon Fighting, BAB +6 | Second off-hand attack | Deferred | two-weapon fighting |
| Greater Two-Weapon Fighting | Dex 19, Improved Two-Weapon Fighting, Two-Weapon Fighting, BAB +11 | Third off-hand attack | Deferred | two-weapon fighting |
| Weapon Finesse | Proficiency with weapon, BAB +1 | Dex instead of Str on light melee attacks | Integrated and verified | exact weapon/proficiency checks |
| Weapon Focus | Proficiency with weapon, BAB +1 | +1 attack with selected weapon | Integrated and verified | parameterised, exact weapon matching |
| Weapon Specialization | Proficiency, Weapon Focus with the same weapon, fighter level 4 | +2 damage with selected weapon | Integrated and verified | `Feats.CATALOG` (`weapon_specialization`); the Weapon Focus prerequisite is a weapon match (`has_feat_for_weapon`), the class prerequisite is the new `class_level` type, and the +2 is a weapon-parameterised `damage` modifier read by `Rules.damage_bonus`; `test_weapon_specialization.gd`, `--advancement-probe` |
| Greater Weapon Focus | Proficiency, Weapon Focus, fighter level 8 | +2 attack with selected weapon | Deferred | level/class subsystem |
| Greater Weapon Specialization | Proficiency, Greater Weapon Focus, Weapon Focus, Weapon Specialization, fighter level 12 | +4 damage with selected weapon | Deferred | level/class subsystem |

### Item Creation feats

All are **Deferred because of the item-creation and downtime dependency**
(crafting costs, XP expenditure, prerequisite spells and magic-item catalogue).
None is exposed as a player choice.

Brew Potion, Craft Magic Arms and Armor, Craft Rod, Craft Staff, Craft Wand,
Craft Wondrous Item, Forge Ring, Scribe Scroll.

### Metamagic feats

All are **Deferred because of the metamagic and spell-slot dependency**
(modified spell levels, casting time, components and area/range handling).
None is exposed as a player choice.

Empower Spell, Enlarge Spell, Extend Spell, Heighten Spell, Maximize Spell,
Quicken Spell, Silent Spell, Still Spell, Widen Spell.

### Monster feat

| Feat | Prerequisites | Benefit | Status | Dependency / next step |
| --- | --- | --- | --- | --- |
| Multiattack | Three or more natural attacks | Secondary natural attacks take −2 instead of −5 | Integrated and verified | `Feats.secondary_attack_penalty`; ghoul claws corrected from authored −2 to computed 0 |

## Verification map

| Test file | Coverage added |
| --- | --- |
| `tests/test_rules.gd` | Existing skill totals, saves, AC, attack, finesse, criticals |
| `tests/test_feats_skills.gd` | 45-skill catalog, trained-only, armor breakdown, Skill Focus/Alertness, the fourteen +2/+2 skill feats (exact pair, no leakage, stacking), proficiency grants and non-proficiency penalties, synergies, typed stacking, take 10/20, aid, opposed ties, rank caps, Dodge, Weapon Focus, Weapon Finesse, Point Blank Shot, Improved Initiative, Toughness persistence, Multiattack, unknown feats, shipped-content validation, holy symbol, take controls, crate take 20 |
| `tests/test_combat_casting.gd` | Defensive check with and without the feat, the +4 in the breakdown, injury checks receiving nothing, duplicate feat text not doubling, failure still spending action and slot, catalog/validation/sheet contract |
| `tests/test_concentration.gd` | Unthreatened and threatened casts, injury DC with spell level, per-interruption checks, disruption spending the action and slot with no effect, defensive success/failure, caster incapacitation, invalid target preserving resources, missing ranks and old saves |
| `tests/test_turn_undead.gd` | Turning math, Knowledge (religion) +2, turn resistance, holy-symbol path through content, Extra/Improved Turning resources and effective level |
| `tests/test_combat.gd` | Initiative, action economy, movement and opportunity attacks, attacks, damage reduction, paralysis, spells, ending conditions, and the committed Power Attack and Combat Expertise trades |
| `tests/test_exploration.gd` | Existing search/lock checks that now use the shared skill engine |
| `tests/test_ui.gd` / `tests/test_narrative_and_save.gd` | Character sheet and dialogue construction against the new breakdowns |

## Deliberate omissions

- Epic feats, flaws, traits, alternative class features, psionics, incarnum,
  binders, maneuvers and non-core expansions are excluded.
- Optional variants (for example variant turning or defense bonuses) are not
  implemented.
- A feat's name appearing in this manifest does not make it selectable. Only
  `Feats.CATALOG` is selectable, and content validation rejects anything else.
