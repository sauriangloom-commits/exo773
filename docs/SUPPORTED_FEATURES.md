# Supported Features and Limitations

This is the authoritative scope statement. If a mechanic is not listed as
supported, it is not implemented, even if D&D 3.5 defines it.

## Playable content

| Feature | Status | Notes |
| --- | --- | --- |
| Main menu, new game, continue, load, settings, quit | Supported | Continue/Load disabled when no compatible save exists |
| Party selection | Supported | Five pregens: Kaelen (Fighter), Sera (Rogue), Aldric (Cleric), Ysolde (Elf Wizard), Mira (Sorcerer). The campaign's `party.min`–`party.max` range is shown and enforced by both the screen and new game (platform range 1–4; Ashwick 3–4) |
| First-person exploration | Supported | Three registered maps: 11×12 Old Gatehouse, 9×9 developer staging map, 11×11 Village of Barovia town square (E3); four facings, doors, objects, NPCs, triggers |
| Persistent area travel | Supported | Manifest-driven area ids and explicit travel effects; per-area doors, removed objects, searched state and visited cells are saved |
| Character sheet | Supported | Abilities, saves, AC, HP, attacks, skill breakdowns, feat benefit rows, equipment, conditions, XP |
| Inventory and equipment | Supported | Equip weapons/armor/shields and use potions; dropping/trading is not supported |
| Quest journal | Supported | Two quests, flag-driven objectives, authored facts and spoiler-gated open questions |
| Dialogue | Supported | Miruna, Corvin and Ashlyn; narrator/creature/NPC speakers; branches, checks, effects |
| DM narration | Supported | Intro, room descriptions, combat log, victory/defeat text |
| Combat encounters | Supported | The Flooded Stores (2 zombies), The Gate-Warden's Crypt (ghoul + zombie), E3 Town Square (2 infected zombies) |
| Victory / defeat / recovery | Supported | Victory narration and autosave; defeat screen with load and main-menu recovery (no Restart button) |
| Save / load / continue | Supported | Four slots (`auto`, `slot1`–`slot3`), versioned JSON |
| Settings and remapping | Supported | Master/music/SFX/ambience volume, text size, action rebinding and confirmed Restore Default Controls |
| Audio hooks | Supported | Generated placeholder music, ambience and SFX; missing files are ignored |

## Rules

### Character statistics

- Six abilities with standard 3.5 modifiers.
- Level-3 pregens with class hit dice, base attack bonus, base saves, skill ranks
  and feats authored in `content/characters.json`.
- AC from armor, shield, Dexterity (armor cap), size and natural armor. Touch AC
  excludes armor, shield and natural armor; helpless targets use Dexterity 0.
- Combat-start flat-footedness (PHB pp. 133-136) is applied. Every combatant
  starts flat-footed and remains so until the start of their first turn: a
  **positive** Dexterity bonus is denied on normal and touch AC, any **dodge**
  bonus (Dodge feat, Combat Expertise) is denied with it, and the creature
  cannot make attacks of opportunity. A negative Dexterity modifier is not a
  bonus and still applies, and a zero modifier changes nothing (PHB p. 136: "If
  you don't have a Dexterity bonus, nothing happens"). A rogue can sneak attack
  a flat-footed target; undead and constructs remain immune to that sneak
  attack. Awareness only removes a surprise round, so an all-aware battle still
  starts flat-footed. PHB p. 134 says the state lasts "until he or she takes an
  action"; this project ends it at the start of that combatant's first turn and
  says so in the round-1 combat-log line, so the reading is visible rather than
  implicit.
- HP, temporary damage, healing, dying, stable, dead and undead destruction.
- XP total per character (no advancement).

### Feats and skills

- All 45 Table 4-2 skills are cataloged with key ability, trained-only status,
  armor check multiplier and action/retry notes (`Skills.CATALOG`).
- Skill totals separate ranks from ability, armor check, feat, synergy,
  circumstance and miscellaneous modifiers; the character sheet shows the full
  breakdown.
- Trained-only skills are unavailable without ranks and explain why. Class and
  cross-class rank caps are available to validation.
- Take 10 and take 20 are available on exploration checks against the object or
  door ahead, and through dialogue `take` options; combat/threat and
  failure-penalty restrictions apply.
- Aid Another (DC 10, +2) and opposed checks with the PHB tie rules are
  implemented as shared helpers.
- Forty-one feats are implemented and re-check their prerequisites on every
  use: Iron Will, Lightning Reflexes, Great Fortitude, Dodge, Improved
  Initiative, Alertness, Skill Focus, Weapon Focus, Weapon Finesse, Point Blank
  Shot, Toughness, Multiattack, Extra Turning, Improved Turning, the fourteen
  +2/+2 skill feats — Acrobatic, Agile, Animal Affinity, Athletic, Deceitful,
  Deft Hands, Diligent, Investigator, Magical Aptitude, Negotiator, Nimble
  Fingers, Persuasive, Self-Sufficient and Stealthy — and the seven proficiency
  feats: Armor Proficiency (light, medium, heavy), Shield Proficiency, Simple
  Weapon Proficiency, Martial Weapon Proficiency and Exotic Weapon Proficiency,
  Power Attack, Combat Expertise, Combat Casting, Cleave, Improved Trip and
  Precise Shot (each with its own section below). Feats in content that are not
  implemented are validation errors, never silent bonuses.
- Parameterised feats use `Name (selection)` (for example
  `Weapon Focus (longsword)`); Toughness is repeatable and stacks.
- Power Attack (PHB p. 98) requires Strength 13 and is a committed choice for
  the active character's turn. The control selects an amount up to current base
  attack bonus; it applies to the character's melee attacks and relevant
  opportunity attacks until the start of their next turn, then expires. It is
  locked after the standard action, so it cannot be changed per attack. Light
  weapons gain no damage; two-handed weapons gain twice; unarmed/natural attacks
  are the light-weapon exception. Ranged and thrown attacks do not receive it.
  `attack_modes` separates melee/thrown/projectile attacks: a dagger's melee
  attack is melee, while its thrown attack is explicit. A missing feat or an
  excess amount is rejected.
- Combat Expertise (PHB p. 92) requires Intelligence 13 and is a committed choice
  for the active character's turn. The control selects a pending amount up to
  `min(5, base attack bonus)`; the pending amount grants nothing until a
  qualifying melee attack, which itself takes the penalty. From then until the
  start of that character's next turn the amount penalises the character's melee
  attacks and opportunity attacks and adds the same value as a dodge bonus to AC
  (normal and touch). Ranged and thrown attacks discard the pending choice and
  never commit it. The dodge bonus is lost while flat-footed or helpless and
  stacks with Dodge; Combat Expertise never adds damage. It is independent of
  Power Attack, so both penalties can apply to one attack while Power Attack adds
  damage and Combat Expertise adds AC. The control is locked after commitment or
  once the standard action is spent.
- Proficiency is authored per character. Equipment categories are
  `simple`/`martial`/`exotic` for weapons, `light_armor`/`medium_armor`/
  `heavy_armor` for armor, and `shield` for shields; exact item names remain
  valid. A manufactured weapon used without proficiency takes -4 on attack
  rolls. Non-proficient armor or a shield applies its armor check penalty to
  attacks and all movement skills, including Ride. Proficiency feats grant their
  category on top of the authored list. Tower Shield Proficiency is deferred
  because there is no tower shield item or cover mechanic.

### Checks and combat

- d20 + modifier vs DC; natural 1/20 handling where applicable. Typed feat
  modifiers are re-evaluated against current prerequisites.
- Initiative (d20 + Dex + Improved Initiative), deterministic tie-breaking.
- One standard, one move and free actions per turn; double move spends the
  standard action; 5-ft step; end turn.
- Melee and ranged attacks, multiple authored attacks per creature, critical
  threat range and confirmation, critical multipliers.
- Range increments and maximum range for ranged weapons.
- Shooting or throwing into a melee (PHB p. 140): a -4 penalty on the attack
  roll when the target is engaged in melee with a friendly character. Engagement
  is the printed one — two characters are engaged if they are enemies of each
  other and either threatens the other — and a target at least 10 ft. from the
  nearest friendly character avoids the penalty even while engaged. Precise
  Shot (PHB p. 98, requires Point Blank Shot) removes it. Ranged spells that
  require an attack roll are weaponlike (Complete Arcane p. 85) and take the
  same penalty, so Scorching Ray is covered while Magic Missile, which has no
  attack roll, is not. Cover and concealment are still not modeled.
- Grid line of sight: ranged attacks, spells and movement require an unblocked
  Bresenham line; walls stop the line.
- Damage reduction with bypass types (zombie DR 5/slashing).
- Attacks of opportunity for threatened movement, standing up, unarmed trip and
  spellcasting while threatened, with one reaction per creature per round
  (cleared each round).
- A ranged attack made while threatened provokes an attack of opportunity from
  each threatening opponent (PHB p. 135). This is a separate condition from
  shooting into a melee: either can occur without the other, and the log names
  which one applied. A ray provokes once, for the casting; firing it adds no
  second reaction.
- Flanking and sneak attack when two allies threaten an enemy (positional, no
  facing), or when the target is helpless or flat-footed.
- **Exceptions not implemented:** no supported character or creature has uncanny
  dodge or Combat Reflexes. Uncanny dodge is a barbarian/rogue class feature the
  slice has no system for, and Combat Reflexes is not in `Feats.CATALOG`, so
  authoring it is a content error, never a silent bonus. The rule above is
  therefore complete for the supported content, not for the whole 3.5 ruleset;
  adding either ability must also update the flat-footed attack-of-opportunity
  denial.
- Dying at 0 to −9 HP, 10% stabilization per round, death at −10; Heal DC 15
  first aid to stabilize.
- Conditions: paralyzed (ghoul, DC 12 Fortitude, 1d4+1 rounds, elves immune),
  dying, stable, unconscious, dead, blessed, mage armor, aided. Round-based
  duration and expiry; limited stacking.
- Undead: no Constitution, destroyed at 0 HP, immune to paralysis; zombies take
  only a single move or standard action each turn.
- Turn undead for the cleric (PHB pp. 159–160). Standard action, no attack of
  opportunity, 3 + Charisma modifier attempts per day, restored by shrine rest.
  The cleric must carry and present a holy symbol; without one the action is
  unavailable with an explicit reason. The turning check (d20 + Cha, +2 with 5
  ranks of Knowledge (religion)) reads
  Table 8-9 for the highest effective Hit Dice affected; turning damage (2d6 +
  cleric level + Cha) is the total effective Hit Dice turned. Targets are undead
  within 60 ft with line of effect, closest first; already-turned undead are
  skipped. Per-creature Hit Dice and turn resistance are authored data, never
  derived from HP, and effective Hit Dice (HD + turn resistance) drive all three
  comparisons: eligibility, capacity spent and destruction. A creature is
  destroyed when the cleric's level is at least twice its effective Hit Dice.

### Spells (complete implemented list)

| Spell | Level | Use |
| --- | --- | --- |
| Magic Missile | 1 | Automatic-hit force damage; one or more missiles by caster level |
| Mage Armor | 1 | Armor bonus buff with duration; range touch, creature touched (PHB p.225) |
| Scorching Ray | 2 | Ranged touch attack, fire damage |
| Cure Light Wounds | 1 | Healing touch |
| Bless | 1 | Party morale bonus |
| Aid | 2 | Temporary HP/morale buff |

Spell slots are tracked per character and restored by shrine rest. Damage taken
while casting forces a Concentration check (DC 10 + damage + spell level, one per
damaging interruption) and a failed check loses the spell while still spending the
action and slot; the spell list offers casting on the defensive (DC 15 + spell
level, no attack of opportunity) as an explicit per-cast choice. Components,
counterspells, metamagic, rituals and spellbooks-as-copying are not implemented.

### Exploration

- Grid movement with walls, closed doors and occupied NPC cells blocking.
- Locked door with key item and Open Lock DC 15 fallback.
- Search checks with one-time object removal and quest flag.
- Take 10/20 buttons resolve the next object or door check; unavailable uses give
  a reason instead of a roll.
- Shrine rest (full recovery).
- Trigger cells that start encounters.
- Manifest-driven area registry, explicit travel destinations, and persistent
  per-area state; the current area and each area's dungeon state are saved together.
- Source-grounded E3 town square with Ashlyn, a breached barricade, a one-time
  infected-zombie encounter and a one-time repair consequence.
- Seeded RNG; seed shown in the header and saved.

## Narrative framework

- JSON dialogues with start node, arbitrary node graph, speaker kind and name.
- Conditional choices (`flag`, `not_flag`, `quest_active`, `quest_complete`,
  `has_item`, `skill_at_least`).
- Skill/ability checks with success/failure branches and a named actor.
- Effects: `set_flag`, `clear_flag`, `quest_start`, `give_item`, `remove_item`,
  `xp`, `gold`, `narration`, `heal_party`, `start_combat`, `open_door`,
  `remove_object`, `rest`, `travel`.
- One-time events through flags and `only_if_missing` item grants.
- Quest updates and victory detection.
- Validation for missing start nodes, broken links, unknown conditions/effects,
  and missing content IDs. Errors are shown on
  load and in the log.

## Interface

- Responsive Control-based UI at a 1280×720 reference size.
- Keyboard, mouse and on-screen buttons; focusable controls with visible states.
- Combat log with rolls, modifiers, DCs, damage, conditions and resource changes.
- Modals keep keyboard focus: Tab and Shift+Tab cycle only the modal's own controls and wrap, background actions stay blocked while one is open, and closing returns focus to the control that opened it (or the first usable control on the screen).
- Refused exploration actions (a wall, a closed door, an NPC in the way, nothing
  in reach, no one who can pick a lock, a used-up or empty object) write one
  line to the narration log and return the same failure dictionary as before; a
  repeated identical refusal is not logged again until another line intervenes.
- Party sidebar with HP/AC, quest tracker, status line (position/facing/target).
- Modal character sheet, inventory, journal, save/load, settings, pause.
- Text labels and symbols accompany color cues (blue/red tokens, gold ring).
- Placeholder art labels in the view and combat grid.

## Persistence

- JSON saves under `user://saves` (`auto`, `slot1`, `slot2`, `slot3`).
- Save version check; corrupt/incompatible files produce a message, not a crash.
- Recovery from an interrupted save: a missing or unreadable primary is replaced
  in memory by the same write's backup, then its temp file. Every candidate runs
  the ordinary load checks and is named in the Load list and the status line; a
  newer primary is still refused (no downgrade). Loading never renames, deletes
  or rewrites a file, and a later save beside a crash's leftovers leaves them
  intact - even when that save fails.
- Settings written by a newer build are read-only: the Settings panel says so in
  a line above its controls, this session's changes still apply, and the file is
  never written back.
- Saved state includes party (HP, conditions, inventory, spells, XP), current
  area, per-area doors/removed objects/searched/visited cells, position and facing,
  world flags, quests, gold, RNG state and encounter completion flags. Settings
  are stored separately from saves.
- Autosave after dialogue completion and combat victory; manual save only in
  exploration. Saving during combat is refused with an explanation.

## Audio

- 14 locally generated WAV placeholders: step, hit, miss, spell, heal, bell, UI,
  victory, defeat, door, combat, menu music, exploration music, dungeon ambience.
- Music and ambience loop; SFX are one-shot.
- Volume controls for music, SFX and ambience; persisted settings.
- Missing audio files are ignored without crashing.

## Trip and prone (player-initiated)

- Trip (PHB pp. 158-159) is a standard action in the combat screen: unarmed or
  with an equipped trip weapon (the shipped light flail carries `trip: true`),
  with the size gate, explicit immunity, reach, unarmed provoke, melee touch
  attack, opposed check with size and stability bonuses, and counter-trip.
- A lost counter-trip while using a weapon pauses resolution with a Drop/Keep
  panel. The player chooses; nothing is rerolled or double-spent, and every other
  action, including End Turn, is refused at the rules and session boundary until
  the choice is made.
- A dropped weapon is a free action onto the ground, not into the backpack.
  Pickup is a move action that provokes, requires the item's own square, and
  yields an unequipped inventory item. Leftover items are recovered only on
  victory; defeat grants nothing. Automatic post-victory recovery is a labelled
  convenience adaptation.
- Prone creatures are marked, use prone AC and attack modifiers, may only crawl
  5 ft as a provoking move action, and can stand up as a move action that
  provokes.
- Improved Trip (PHB p. 96) is implemented for the player-initiated path: an
  unarmed trip no longer provokes, the attacker's trip check gains +4 (the
  touch attack, the defender's check and a counter-trip gain nothing), and a
  successful trip offers one immediate melee attack against the same opponent.
  PHB p. 96 grants "a melee attack", not the trip method, so the player chooses
  at the decision: the equipped weapon's legal melee mode or an unarmed strike.
  Ranged modes are refused, and nothing is drawn, equipped or re-gripped. The
  extra attack spends no second standard action, inherits committed Power Attack
  and Combat Expertise, and can be declined. It never chains into another trip
  or follow-up.
- Verified in an exported build for player-initiated Trip against NPCs, including
  Improved Trip. NPC-initiated Trip is not implemented, so the player never
  answers a counter-trip prompt as the defender. Mounted trip and non-listed trip
  weapons are unsupported.

## Cleave (own and off turn)

- Cleave (PHB p. 92) triggers from a party member's resolved melee attack — on
  their own turn or off turn — when that attack drops a creature (below 0 hp or
  dead) and another living enemy is within the attacker's reach. The trigger is
  recorded against the attacking character, weapon and attack context, not the
  active combatant, so an opportunity attack that drops a creature qualifies.
  Ranged attacks, spells and damage-over-time effects do not; NPC attackers do
  not take the feat.
- Only legal targets — living enemies in reach, excluding the dropped creature
  and the attacker — are offered. The granted attack uses the same weapon and
  the triggering attack's own base bonus; target-specific modifiers for the new
  target are evaluated afresh (helpless +4, cowering +2, flanking, prone,
  reach), so a bonus that no longer applies is never copied. The committed Power
  Attack and Combat Expertise context carries over. It spends no standard action
  (and no action at all when it arrives off turn) and allows no movement or
  5-foot step.
- An off-turn decision does not transfer turn ownership. The original combatant,
  the interrupted route and its remaining opportunity-attack budget are kept in
  a bounded resume record; accepting or declining re-validates it and then
  continues the interrupted action instead of skipping it. A dead or
  incapacitated actor, an invalid target, a changed turn or the end of the
  encounter voids the continuation.
- Cleave is usable once per round per combatant across own and off-turn uses;
  the use is recorded when the extra attack is taken and cleared at round start.
  Declining spends nothing, duplicate submissions are refused, and an attack
  granted by Cleave cannot chain. Eligibility is re-checked at resolution.
- The main menu's "Combat Training / Rules Demonstrations" entry runs a
  standalone Cleave demonstration on QA fixture characters with no campaign
  save, XP or progression.
- The supported minimum window is 1280x720, enforced by `Window.min_size`; the
  combat sidebar scrolls so decision controls stay reachable at the largest
  text scale (1.6x). 1024x600 is not a supported target.
- Great Cleave, unlimited chains, and full-attack/iterative interactions are not
  implemented.

## Foundation extension surface

- **Authored vocabulary:** `ContentSpec` is the single registry for effect and
  condition types, their required fields and their id references. Content
  loading validates against it and the runtime guards consult it, so adding a
  type is one row, one handler and one test rather than three parallel lists.
- **Passive modifiers:** declarative `Feats.CATALOG` rows (`modifiers` with
  target/type/value, optional `condition`, `weapon_parameter`) resolved through
  `Feats.modifier` and `Rules.stack_bonuses`; prerequisites re-checked on use.
- **Active options:** `Encounter` methods that spend the action/resource before
  rolling and return one result dictionary consumed by UI, log and tests.
- **Decisions and reactions:** explicit `pending_*` dictionaries, resolver
  methods and bounded resume records; reactions resolve without spending the
  reactor's own action.
- **Checks:** `Skills.check`, `Skills.opposed_check`,
  `Rules.opposed_ability_check` with take 10/20, retries, synergies, armor
  penalties and aid another in one module.
- **Persistence:** character/party/world state round-trips through versioned
  saves; encounter state is deliberately unsaved. Demonstrations set
  `Game.training_mode`, which suppresses victory effects, XP and the autosave.
- **Content validation:** unknown types, missing fields, wrong field kinds and
  missing item/quest/encounter/area/skill ids are load errors with explicit text.
- **Evidence:** `tests/test_extensibility.gd` pins the vocabulary and validation
  contract; the existing feat, trip, Cleave and turn-undead tests are the
  representative consumers of each extension pattern.

## Not supported

- Only the 41 feats listed above are selectable. Every other PHB feat in
  [FEATS_SKILLS_COVERAGE.md](FEATS_SKILLS_COVERAGE.md) is deferred behind the
  dependency named there (combat actions, full attacks, cover, spell schools,
  spell resistance, item creation, mounts, advancement, wild shape).
- Full D&D 3.5 rules: grapple, disarm, sunder, bull rush, overrun, mounted
  combat, two-weapon fighting, player iterative/full attacks, readied/delayed actions,
  rebuking/commanding/bolstering undead, spontaneous casting outside
  Mira's fixed sorcerer list, domains, familiars, animal companions,
  multiclassing, prestige classes, level advancement, crafting, shops, traps,
  diseases, poisons, environmental hazards, swimming/climbing, flight.
- Cover, concealment, area-of-effect spells, spell resistance,
  spell penetration, counterspells, readied and delayed actions, casting while
  grappled, weather or ongoing-damage interruptions. Combat Casting's +4 applies
  to defensive-casting checks only; its grappling/pinned clause is not modeled.
- Encumbrance, ammunition tracking, item durability, weight-based movement.
- Party AI, companions acting independently, formation, splitting the party.
- Full canonical Ravenloft geography, factions, NPCs, dark powers or campaign
  events. Only the Village of Barovia town square (E3) is a bounded
  source-adapted area; the Old Gatehouse and staging map remain invented demo
  content.
- Final art/audio, localization, controller support, touch layout, colorblind
  palette validation, screen-reader support, and a fully re-verified exported build.
- Dropping items, trading between characters, containers, item identification.
- Save migration across schema versions beyond the version refusal message.
- Settings migration/versioning.
- Pause-time behavior for audio beyond volume changes.

## Honest limitation notes

- **UI construction vs interaction:** automated tests instantiate every screen
  and panel, but do not click every button or complete a save/load through the
  modal UI. Combat grid mouse clicks and rebinding were inspected but not
  exhaustively automated.
- **Audio:** files import and hooks are called; audible quality was not verified
  in a headless environment and was not subjectively reviewed.
- **Export:** the corrected batch-5 Windows x86_64 candidate
  `../.ravenloft-candidate-featskills5b/RavenloftFoundation.exe` was built,
  launched windowed with `-- --demo-power-attack` under isolated `APPDATA`, and
  the feature-specific Power Attack controls and opportunity-attack  sequence were
  repeated in that exact executable. The batch-6 candidate
  `../.ravenloft-candidate-featskills6/RavenloftFoundation.exe` (110,132,152
  bytes, SHA-256
  `ee786089b2d3be679aaf2008b9f543423a040969f862cd09ce8678b0e4855bf`) repeated the
  Combat Expertise pending, commit, opportunity-attack, incoming-attack (AC 19)
  and expiry sequence through its visible controls. A full E3 loop was not
  replayed in either candidate; the source E3 run remains the end-to-end evidence.
- **Native interaction:** the gatehouse loop, save/load, combat categories, defeat
  and both recovery paths, E3 victory/dialogue/barricade/travel/return and key
  rebinding were exercised. Restore Default Controls is covered by the automated
  persistence test. The final executable was checked for independent launch/load.
- **Rendering:** screenshots were inspected at 1280×720, 1366×768 and 1920×1080.
  1024×600 is **not** a supported size (the window minimum is 1280×720). Since
  2026-11-20 the client area is the layout surface and 100 %/160 % text are
  verified at 1280×720, 1600×900, maximized and fullscreen by `--layout-probe`.
  Mouse-wheel scrolling, focus traversal and high-DPI beyond those captures were
  not exhaustively tested.
- **Power Attack scope:** the committed choice is verified for the supported
  single attack action, including relevant opportunity attacks. The two-handed
  multiplier is exercised with synthetic `two_handed` metadata because no shipped
  weapon authors it; wielding a one-handed weapon in two hands and full attacks
  are not implemented. Dagger melee and explicit thrown modes are separate; only
  the thrown mode is ranged. The native QA fixture is temporary and not shipped.
- **Combat Expertise scope:** verified for the supported single attack action,
  including the opportunity attack and the incoming-attack AC calculation.
  Fighting defensively (PHB p. 139) and total defense (p. 141) are not
  implemented, so their interaction is deferred rather than guessed; full attacks
  and one-handed weapons wielded in two hands are also absent. "Until your next
  action" is interpreted as until the start of the character's next turn. No
  shipped pregen or authored encounter has the feat, so the native demonstration
  uses a temporary QA fixture.
- **Turn undead scope:** only the good-cleric turn/destroy path exists; rebuking,
  commanding, bolstering and dispelling are not implemented. Extra Turning
  (repeatable +4 uses/day) and Improved Turning (+1 effective level) are
  implemented against this path, but no shipped pregen has them. Turned undead
  flee for 10 rounds by the best route their single
  move action allows, or cower when no route increases the distance. The effect
  ends when the cleric who turned them moves from beyond 10 ft to within 10 ft;
  standing within 10 ft, an ally approaching, or the creature approaching do not
  break it. They remain in the encounter: there is no disengagement or map-edge
  escape, so an encounter still ends only when every enemy is destroyed, turning
  awards no XP by itself, and a
  turned duration is never persisted (combat remains unsaveable). Daily uses do
  persist.
- **Weapon access in combat:** the combat screen lists the readied weapon and every
  weapon carried in inventory. Sheathing and drawing are separate move actions
  (PHB p. 142) and either can spend the standard action as a move (p. 138), so a
  swap costs both slots and the previous weapon stays carried. A light crossbow must
  be loaded with a move action that provokes (p. 115) before it can fire, and firing
  spends the shot; bolts are a free draw, so ammunition is not tracked. A loaded
  crossbow stays loaded when it is stowed, and a spent shot is never restored by
  switching. Loaded state belongs to the encounter, not to a save.
- **Shields:** the shield control straps on a shield you carry (move action,
  PHB p. 142) and offers an explicit loose entry that unstraps **and drops** it on
  your square; Pick up recovers it. The shield bonus, armor check penalty and
  proficiency rules come from the existing equipment path. A second shield cannot be
  strapped over the first, and a two-handed weapon blocks strapping one on.
- **Threat:** you threaten a square only when you are armed for melee (PHB p. 137)
  - a readied melee weapon, a natural weapon, or Improved Unarmed Strike with empty
  hands ("armed" unarmed attacks, p. 139). Ordinary empty hands can still attempt a
  strike, but they grant no threat, no flanking, no engagement and no opportunity
  attack, and an action that provokes near an unarmed enemy resolves no reaction. A
  crossbow never threatens and is never used as an improvised melee blow.
- **Skill breadth:** all 45 skills resolve checks, but only the authored uses
  exercise them; swimming, crafting, tracking, stealth, traps and item activation
  remain cataloged without a world subsystem. See
  [FEATS_SKILLS_COVERAGE.md](FEATS_SKILLS_COVERAGE.md).
- **Content breadth:** three registered areas, five encounters (three campaign,
  two clearly labelled QA scenarios), three dialogues, two quests and six spells
  are a demonstration, not a campaign.

- **Unarmed attacks:** an empty-handed character can Attack; the strike is
  light, bludgeoning and always nonlethal (PHB p. 139): 1d3 Medium, 1d2 Small,
  1d4 Large, tracked as a separate nonlethal total that makes the target
  unconscious once it exceeds current hit points. Attacking unarmed provokes an
  attack of opportunity from the armed target, never from an unarmed bystander.
  Undead and constructs are immune and take nothing. Improved Unarmed Strike
  (PHB p. 97) grants armed status, the printed no-provocation clause, and the
  choice of lethal or nonlethal damage with no penalty; a character without the
  feat can still strike lethally at the printed −4 (PHB p. 147). No feat adds a
  damage die - increased unarmed damage is a monk class feature and is not
  implemented.
- **Nonlethal state:** nonlethal damage equals current hit points → staggered
  (a standard action or a move action, not both, with the controls disabled
  accordingly); more than current hit points → unconscious and helpless. Lethal
  damage and healing move the thresholds in either direction, zero nonlethal
  damage never creates a state, and clearing it never removes another
  incapacity. Magical healing (cure spell, potions, authored healing) removes
  nonlethal damage equal to the amount it cures, even at full hit points;
  natural hourly recovery is replaced by rest clearing the total.
