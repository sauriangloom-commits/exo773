# Adaptation and Assumptions Log

These are consequential decisions made while converting tabletop D&D 3.5 into a
single-player Godot game. Each entry states the choice and its reason. Minor
presentation choices are omitted; nothing here changes a rule silently.

## World and party

1. **Neutral invented location.** The slice uses *Example Location — The Old
   Gatehouse*, with original NPCs and a quest. Reason: implementing canonical
   Ravenloft geography or events without a setting source would risk inventing
   lore. ECR supplies tone, not plot. Everything is labelled example content.

2. **Four-person party from five pregens.** The player chooses 1–4 of five level-3
   characters. Reason: bounded, testable party composition while still offering a
   configuration choice. Mira is an alternate, not a fifth active member.

3. **Fixed level-3 pregens; no level-up.** XP is tracked and saved, but class
   features, ability increases and spell selection do not advance. Reason: the
   slice needs stable, auditable numbers; advancement is a campaign-layer feature.

4. **Start at (5,10) facing west.** The opening view looks down the gatehouse
   corridor toward Miruna instead of into a wall two squares away. Reason:
   readable first impression without changing the map.

## Space and movement

5. **One 5-ft grid for exploration and combat.** Exploration cells and combat
   squares are both 5 ft. Reason: one spatial model prevents conversion bugs and
   lets combat terrain come from the same authored rows.

6. **Diagonal movement costs 5 ft.** Tabletop 3.5 uses the 5-10-5 alternating
   diagonal. The game charges 5 ft per diagonal. Reason: simple, predictable
   movement on a square grid; documented as an intentional adaptation, not a
   claim of tabletop accuracy. `BattleMap.distance_ft` is the authority.

7. **Discrete facing in exploration, no facing in combat.** Exploration has four
   cardinal facings; combat tokens have no facing and flanking is positional.
   Reason: Wizardry-style exploration and a clean tactical grid; tracking facing
   for every combatant would add complexity without changing the supported rules.

8. **Grid line of sight; no cover or concealment.** Ranged attacks, spells and
   movement require a Bresenham line of sight through unblocked cells
   (`BattleMap.has_line_of_sight`). Cover bonuses and concealment miss chance
   remain deferred. Reason: LOS is essential to ranged/spell targeting; cover is
   a separate subsystem, not an invisible approximation.

9. **Attacks of opportunity are partial.** Threatened movement and ranged attacks
   in melee provoke; every tabletop trigger (standing up, casting, grappling,
   etc.) is not modeled. Reason: the supported trigger set covers the authored
   encounters; the rest is explicitly deferred.

## Combat and rules

10. **Initiative ties are deterministic.** The engine breaks ties without asking
    the table, so a seeded test reproduces the same order. Reason: deterministic
    tests and saves. The log still shows the rolls.

11. **Monster AI is intentionally simple.** Enemies choose a reachable conscious
    target, move toward it and attack; zombies obey single-action restrictions;
    the ghoul uses its paralysis attack. Reason: a readable, auditable baseline
    rather than pretending to be a tactical AI.

12. **Six spells only.** *Magic Missile*, *Mage Armor*, *Scorching Ray*, *Cure
    Light Wounds*, *Bless*, *Aid*. Components, material foci, concentration,
    counterspells, metamagic and most spell interactions are absent. Reason:
    enough variety to exercise attack, defense, healing, buffing and slot
    tracking without implying full spellcasting support. Mage Armor was corrected
    from the earlier self-only implementation to PHB p.225 range touch/creature
    touched; its UI now permits ally targeting.

13. **Spell slots are tracked per character; rest restores them.** The shrine is a
    deliberate full-recovery point. Reason: the slice needs a recovery loop, and
    tabletop rest has campaign-level resource pressure that is out of scope.

14. **Dying/stabilization is implemented, but death is recoverable.** At 0 to −9
    HP a character is dying, stabilizes on a 10% check, and dies at −10. A party
    wipe routes to a defeat screen offering load or restart. Reason: preserve the
    tabletop death spiral while keeping the demo recoverable.

15. **Damage reduction checks the damage type.** Zombie DR 5/slashing is applied
    from the weapon's authored damage type. Reason: the authored monsters need it;
    the full damage-type interaction matrix is out of scope.

16. **Undead are destroyed at 0 HP.** No negative-HP dying state for undead.
    Reason: MM undead traits.

17. **Elf immunity to ghoul paralysis.** Ysolde is an elf and is exempt from the
    ghoul's paralysis. Reason: PHB racial trait + MM ghoul ability.

18. **No encumbrance.** Item weight and carrying capacity are ignored. Reason:
    inventory management is present, but weight bookkeeping would add noise to a
    short slice. The Carrying Capacity table was read and deliberately not used.

19. **XP is a progress indicator only.** Encounters and dialogue award XP, saved
    with the character. Reason: gives feedback and a hook for the campaign layer
    without implementing advancement.

19a. **Turning never removes a creature from the encounter.** Turned undead flee
    or cower but stay in play; the encounter still ends only when every enemy is
    destroyed. Reason: PHB turning is a 10-round condition, not a kill, and the
    slice has no disengagement or map-edge escape mechanic. Consequences are
    explicit: a turned creature awards no XP, victory still requires destroying
    the remaining enemies, and because combat is unsaveable, a turned duration is
    never persisted. Daily uses and rest recovery are persisted normally.

19b. **The 10-ft rule is approach-triggered, not a distance check.** PHB p.159
    says a cleric who *approaches* within 10 ft breaks the turning, and that
    standing within 10 ft does not. The engine therefore records which cleric
    turned each creature and breaks the effect only when that character moves
    from outside 10 ft to inside 10 ft. A turned creature walking closer, an ally
    approaching, or the cleric already standing close all leave the effect
    intact. Reason: a simple "distance <= 10" test would contradict the parenthetical
    in the source and make turning useless at close range.

19c. **Fleeing uses one move action.** "Flee by the best and fastest means
    available" is implemented as the farthest legally reachable square within the
    creature's speed, routed around walls and occupied squares with the same path
    rules as movement. Running (4x speed), charging and squeezing are outside the
    supported movement model. If no legal route increases the distance — cornered,
    blocked, or out of budget — the creature cowers for that round and tries again
    on its next turn. Reason: bounded, auditable movement rather than a new
    navigation system.

19d. **A creature covers a line only when it crosses the square's interior.**
    The printed rule asks whether a line passes "through a square occupied by a
    creature". On a grid, a line that merely shares an edge (two allies standing
    in one row, or the segment between two corners of a shared border) is not
    counted, and a diagonal passing exactly through a corner enters only the
    diagonal square. Reason: counting edge contact would make a creature beside
    the line block every shot along that row and make a diagonal neighbour always
    grant cover. Consequence: a body that only touches the line at an edge gives
    no cover. The four corner lines make that rare, but it is a real difference
    from a miniatures mat, where the physical line is what matters.

19e. **Wall cover is left to line of sight.** A wall on the line either blocks
    line of effect - the attack is refused as total cover - or, when the centre
    line clears it, grants nothing. The printed rule would give +4 AC when a
    corner line passes through a wall square. Reason: the maps are coarse and
    the existing contract is "no line of effect, no attack"; a second, partial
    cover term for walls would report +4 AC against targets the game otherwise
    treats as either hittable or unhittable. Low walls, which the printed rules
    treat as cover without blocking line of sight, have no terrain type here.

19f. **Reach melee does not take creature cover.** PHB p.151 says a reach
    attacker uses the ranged cover determination, so a creature between a
    glaive and its target would give +4 AC. Melee attacks here never read
    creature cover. Reason: the bounded scope is ranged attacks; no supported
    character uses a reach weapon, and a melee cover path would change numbers
    in fights this change did not intend to touch. This is a recorded deviation,
    not a claim of full cover support.

19g. **The defensive stances commit rather than toggle, and one printed clause is
    unreachable here.** Fighting defensively and total defense are separate
    actions. A mere selection is intent: it grants no bonus, spends nothing and
    may be cancelled or replaced by total defense; only the commit point of a
    legal attack turns the selection into a stance, so a refused or cancelled
    attack cannot leave a bonus behind. Once active it is locked until the start
    of the character's next turn. Fighting defensively stacks with Combat
    Expertise (RC p.54), whose dodge bonus and attack penalty stay melee-only,
    and the AC line shows the combined number. Total defense refuses both Combat
    Expertise and an active fighting-defensively stance, as printed. The Tumble
    replacement (+3/+6 for 5 ranks, PHB p.84) is implemented and unit-tested with
    a fixture, but no shipped character has Tumble ranks, so it cannot be reached
    in campaign content. The control is labelled `Defend`: the full label made
    the four-column action grid wider than the sidebar's 340 px minimum, the
    scroll container's bars then oscillated and stalled the frame queue, so the
    tooltip carries the full name and the sidebar now reserves its vertical bar
    so no wrapped label can repeat that loop.

19h. **Combat-scope effects end with the encounter, not only with the turn.**
    Fighting defensively, total defense and Combat Expertise all last until the
    start of the character's next turn, and that turn is measured inside one
    encounter. `Encounter.finish` therefore removes them, together with the
    encounter-only selections, before it emits `changed`; the victory autosave
    is written from that signal, and `Character.to_dict` serializes `effects`.
    Without the cleanup a defensive finishing blow or a total defense followed
    by an ally's kill left the dodge bonus visible in exploration and in the
    save, although the next fight's flat-footed round denied it. Unrelated
    lasting effects (bless, mage armor, aid, conditions) are preserved, because
    only the three combat-scope ids are cleared. A defeat exit clears them too
    and writes no autosave.

19i. **A bull rush push stops at a wall or an occupied square, and a rush with
    no space behind the defender is refused outright.** PHB p. 154 says how far a
    won bull rush pushes but says nothing about what happens when the defender
    cannot move that far. The engine applies the ordinary movement restriction
    ("you can't move into a blocked or occupied square") to the forced movement:
    the push stops in the last legal square, the rusher follows only as far as he
    can legally stand, and the log names the wall, the occupied square or the map
    edge. Because the grid cannot represent two creatures in one square, a rush
    whose first 5-ft push has no legal destination is refused before the reaction
    and the roll, which is an engine limitation rather than a printed refusal. The
    printed distance cap ("you can't exceed your normal movement limit") is kept.

19j. **The entry step costs movement, and bull-rush movement is resolved atomically.**
    PHB p. 154 opens with "First, you move into the defender's space", so the
    engine treats that step as 5 ft of the rusher's own movement: a character with
    less than 5 ft left cannot bull rush, and each extra 5 ft of push is paid from
    the same budget. The defender's reaction resolves against the pre-move cells
    and before the opposed check, matching the printed order, but the engine never
    stores the transient overlap of two creatures in one square: on a win the
    rusher is committed to the vacated square, on a loss he stays where he stood
    (equivalent to stepping in and back out, and never charged twice). Grid
    adjacency includes diagonals, so "straight back" follows the rusher-defender
    axis whether it is orthogonal or diagonal.

## Narrative and content

20. **Dialogue checks default to the best conscious party member.** Content can
    pin an actor by id; otherwise the engine chooses the highest skill total and
    names that character in the choice label. Reason: avoids forcing the player to
    solve party optimization before every conversation while keeping the acting
    character explicit.

21. **Dialogue effects are data, not scripts.** Flags, quests, items, gold, XP,
    narration, combat starts, door opens and rest are effect dictionaries handled
    by `GameSession`. Reason: writers can add consequences without editing the
    runner; validation catches unknown types.

22. **One-time dialogue gating uses flags.** The quest-accept option remains
    visible after acceptance but is disabled with a reason. Reason: players can
    see why an option is unavailable instead of wondering where it went.

23. **Autosave points.** Autosave occurs after a dialogue ends and after combat
    victory; manual saving is allowed only in exploration. Reason: prevents saving
    mid-combat in an inconsistent state while protecting progress through the
    authored loop.

24. **Placeholder prose is deterministic and labelled.** Every authored string
    marked `(EXAMPLE ...)` is original text written for this project. No long
    passages from the PDFs were reproduced. Reason: demonstrate the framework
    without substituting for the future campaign writing.

## Presentation and assets

25. **Procedural placeholder art.** Walls, tokens, NPCs, items and UI are drawn
    from shapes and theme colors. No third-party game art. Reason: replaceable,
    original and license-safe.

26. **Generated placeholder audio.** 22,050 Hz mono WAV files synthesized locally.
    Missing audio is ignored rather than fatal. Reason: establish the hooks and
    volume controls without spending the budget on final sound design.

27. **1280×720 reference viewport, scalable UI.** The interface is laid out for
    1280×720 and expands with the window; Phase 2 inspected 1280×720, 1366×768,
    1920×1080, 1024×600 and 1.6× text. The exploration sidebar, dialogue panel and
    combat legend now scroll or wrap instead of clipping. Reason: a practical
    baseline for a 2D pixel-art presentation later.

28. **Godot 4.7.2 / GUT 9.6.1.** These are the versions actually present and
    verified. GUT's update notice mentions 9.7.1, but 9.6.1 is what runs here.

## Feats and skills (batch 1)

29. **Dodge is a general +1 dodge bonus.** Tabletop Dodge is chosen against one
    opponent each round. This slice applies the bonus to all attacks, including
    while helpless, because there is no per-attacker target selection. Reason:
    the alternative would be an inert feat or a hidden target choice; the
    adaptation is visible and tested. Target selection is deferred.

30. **Toughness HP is applied once on entry.** `Character.from_content` adds +3
    HP (and current HP) for each Toughness selection; `from_dict` never reapplies
    it, so save/load is stable. Printed monster HP often already includes the
    feat, so the infected zombie authors 39 base HP and enters play at 42. Reason:
    the stat block's final total must not be double-counted.

31. **Multiattack is computed, not authored.** Secondary natural attacks take -5,
    or -2 with Multiattack, inside `Rules.attack_bonus`. The ghoul's claw attack
    data is therefore 0 rather than a baked-in -2, and the feat is re-checked
    against the creature's three natural attacks. Reason: one rule, one place;
    removing the feat now changes the numbers correctly.

32. **Take 10/20 is an explicit exploration action.** Two buttons resolve the
    skill check on the object or door ahead. They are not a hidden substitution
    for every roll, and they report the reason when the check cannot be taken
    (combat/threat, failure penalty, trained-only, no check ahead). Reason: the
    player should choose the careful action and see its cost/limits.

33. **Proficiencies are authored, not inferred, and now drive penalties.** Each
    pregen lists class weapon/armor/shield categories or exact weapons. Feats
    grant categories on top without rewriting that list. Batch 3 models the -4
    manufactured-weapon penalty and applies non-proficient armor/shield ACP to
    attacks and movement skills (including Ride). `proficiency_schema` 2 migrates
    older saves once from class defaults. Reason: class-derived inference would
    hide content errors and complicate multiclassing later. Tower Shield remains
    deferred because no tower shield item or cover mechanic exists.

34. **The skill catalog is broader than the authored world.** All 45 Table 4-2
    skills resolve checks with the shared engine, but swimming, crafting,
    tracking, stealth, traps and item activation have no world subsystem. They
    are marked Cataloged or Partially supported, never claimed as complete play.
    Reason: rules support and content support are different claims.

35. **Unknown feat names are content errors.** `Feats.CATALOG` is the only
    selectable set. A typo or an unimplemented feat fails validation and is never
    silently ignored. Reason: a feat that does nothing is worse than a clear
    authoring error.

36. **Power Attack is committed per character until that character's next
    turn.** The combat screen's amount control is the selection surface; setting
    it stores the choice in `Encounter.power_attack_committed` for the active
    character, and that mechanical state is what attacks use. The choice applies
    to all of that character's melee attacks and relevant attacks of opportunity
    until the start of their next turn, when it expires. The control is disabled
    once the standard action is used, so the player cannot choose a different
    amount for a later attack in the same turn. PHB p. 98; this slice still has
    one attack action per turn, so a full-attack sequence is not implemented.
    Light weapons still take the attack penalty but gain no damage; two-handed
    damage doubling uses `two_handed` metadata, and wielding a one-handed weapon
    in two hands is not implemented. Weapon modes are explicit: `attack_modes`
    distinguishes melee, thrown and projectile attacks. Legacy `range_increment`-
    only data is ranged-only; ordinary weapons default to melee. A dagger's
    melee attack is melee, its thrown attack is explicit and does not receive
    Power Attack, and opportunity attacks use the melee mode. Reason: match the
    source duration and avoid classifying every dagger attack as ranged.

37. **Combat Expertise commits on a qualifying melee attack, not when the
    control changes.** PHB p. 92 says the attack penalty and dodge bonus apply
    "until your next action" and are chosen before attacking. The combat screen
    therefore stores a *pending* amount that grants nothing, and commits it
    immediately before a qualifying melee attack resolves; that activating attack
    itself takes the penalty. A ranged or thrown attack discards the pending
    choice instead of committing it. The committed amount applies to later melee
    attacks, opportunity attacks and the character's AC until the start of their
    next turn. Interpreting "until your next action" as the start of the next turn
    is an engine adaptation: there is no immediate/swift-action subsystem and
    opportunity attacks are reactions, so ending the effect at the turn boundary
    is the auditable reading. The bonus is a dodge bonus, so it is omitted when
    the defender is flat-footed or helpless (PHB p. 135), and it stacks with
    Dodge. It never adds damage. Fighting defensively (p. 139) and total defense
    (p. 141) are not implemented, so their interaction is deferred rather than
    invented; full attacks and one-handed weapons wielded in two hands are also
    absent. Reason: the source distinguishes activation timing and bonus type from
    Power Attack, and copying Power Attack's commit-on-control behavior would
    grant AC before the required attack.

38. **Combat-start flat-footedness is applied, not adapted away.** Earlier
    versions documented the omission as a bounded adaptation. PHB p. 133 states
    that "a character who has not yet acted during a combat is flat-footed",
    that such a character loses its Dexterity bonus to AC, and that it cannot
    make attacks of opportunity; a rogue can also sneak attack a flat-footed
    opponent. `Encounter.begin` now marks every combatant and `_begin_turn`
    clears the mark at the start of that combatant's first turn. The project
    reads "before their first regular turn" as "until the start of the turn"
    and says so in the round-1 log line instead of leaving it implicit. Only a
    positive modifier is denied: PHB p. 136 says "If you don't have a Dexterity
    bonus, nothing happens", so a Dexterity penalty is not a bonus and still
    applies, and any dodge bonus (Dodge, Combat Expertise) is denied along with
    the Dexterity bonus by the same page. Undead and constructs remain immune to
    the sneak attack. Reason: initiative previously had no consequence for AC or
    reactions in round 1, which distorted the tactical evaluation of an ordinary
    fight; the rule is printed, testable in isolation, and needed no new
    subsystem. This entry supersedes the first version of this milestone, which
    removed the raw Dexterity modifier and kept dodge bonuses; both were wrong
    against the printed text and were corrected before the next candidate.

39. **Ranged attacks: the into-melee penalty and the provocation are separate
    rules, and both reach ranged spells.** PHB p. 140 prints the -4 for shooting
    or throwing into a melee, defines engagement ("Two characters are engaged in
    melee if they are enemies of each other and either threatens the other"),
    exempts a target at least 10 ft. from the nearest friendly character, and
    exempts Precise Shot. PHB p. 135 prints the provocation for making a ranged
    attack while threatened. Both are now implemented from one helper,
    `Encounter._into_melee_penalty`, and stay separate: the penalty changes the
    roll and depends on the target's neighbours; the provocation happens before
    the roll and depends on the attacker's. Neither is a proxy for the other and
    the log names whichever applied. Precise Shot joins the feat catalog with its
    printed prerequisite (Point Blank Shot) and no passive modifier, because its
    only effect is the exemption. Complete Arcane p. 85 makes any attack-roll
    spell a weapon and p. 73 gives Precise Shot the same exemption for ranged
    spells, so Scorching Ray takes the penalty and Magic Missile cannot; casting
    provokes once, because one spell is one action that is both cast and fired.
    Two bounded readings are recorded rather than invented: a helpless target
    counts as not engaged (the page's "unless he is actually being attacked"
    needs per-round attack tracking this slice does not have), and Complete
    Arcane's version of Point Blank Shot for spells is not implemented, only its
    Precise Shot exemption. Reason: the earlier build implemented the provocation
    and documented "firing into melee is not modeled", which made a bow strictly
    worse than a sword in the case the rules single out, while needing no new
    subsystem.

40. **Concentration resolves from printed pages 69, 70, 140 and 170, and casting
    on the defensive is a per-cast player choice.** PHB p. 69 lists Concentration
    as a Constitution check usable untrained; p. 70 gives DC 10 + damage dealt,
    adds the level of the spell being cast, and says "make a check for each one;
    any failed check indicates that the task is not completed"; p. 170 repeats the
    injury DC and states that a wizard's or cleric's spell is lost from
    preparation; p. 140 states that casting defensively provokes no attack of
    opportunity, requires a DC 15 + spell level check, and that failure loses the
    spell. The encounter now spends the standard action, the slot and the prepared
    cast as part of beginning the cast, then resolves reactions: a defensive cast
    makes one check and never provokes, an ordinary threatened cast provokes once
    per threatening enemy and makes one check for each interruption that deals
    damage. A failed check, or a caster dropped by the reaction, produces no spell
    effect and keeps the expenditure; an invalid target still returns before any of
    that. Rays were already one action that both casts and fires, so the defensive
    branch replaces the same single provocation and never adds a second "firing"
    one. Two readings are recorded: incapacitation is checked after the reactions
    rather than mid-spell (no partial spell exists), and the order of multiple
    checks is the engine's fixed threat order, not a player choice.

    Authoring: `concentration` is `untrained: true` in `skills.gd` with ability
    `con`, and `Skills.total` is ranks + Constitution modifier, so the modifier is
    applied once and the skill is never treated as trained-only. No shipped caster
    has ranks in it, and no skill-point ledger survives that would let them be
    reconstructed, so the pregens keep their existing (empty) allocation and cast
    with the Constitution modifier alone; they were not rebuilt or optimized for
    this rule, and old saves with no `concentration` entry read as zero ranks.
    Readied actions, counterspells, grappling, weather and ongoing-damage
    interruptions remain out of scope.

41. **Combat Casting is implemented for its defensive clause only.** PHB printed
    p. 92 reads: "You get a +4 bonus on Concentration checks made to cast a spell
    or use a spell-like ability while on the defensive (see Casting on the
    Defensive, page 140) or while you are grappling or pinned." Grappling and
    pinning have no subsystem here, so the feat grants the +4 only when the
    encounter marks the check as a defensive cast; the condition lives in the
    skill-check options and the feat's modifier, not in a special case inside the
    check. The bonus is untyped, as printed, and takes the best value rather than
    summing. Because the architecture applies feat modifiers per feat text, a
    non-repeatable feat is now counted once per character even if a save contains
    the text twice (content validation still reports the duplicate as an error),
    so a corrupted save cannot double the bonus. No pregen has the feat and none
    was given it. The character sheet's benefit line states the grappling clause
    is not modeled.

42. **Carried weapons are readied with the printed action, and crossbows are
    loaded rather than free.** PHB printed p. 142 says drawing a weapon "requires a
    move action", and p. 115 says "Loading a light crossbow is a move action that
    provokes attacks of opportunity" and that operating one "requires two hands";
    p. 113 makes drawing ammunition a free action for crossbows ("crossbows and
    slings require an action for reloading"), so bolts are not inventoried. The
    combat screen's weapon control lists the readied weapon plus every weapon the
    character carries; inspecting it costs nothing, while choosing another weapon
    calls the encounter and spends the move action, so the UI cannot silently change
    equipment. **Corrected in the weapon-state checkpoint:** an earlier version of this entry
    folded stowing into the draw and claimed the build never cost less than the page.
    That claim was wrong and is withdrawn. Sheathing and drawing are separate move
    actions now, and PHB printed p. 138 ("You can take a move action in place of a
    standard action ... put away a weapon and climb one-quarter of your speed (two
    move actions)") lets the second one spend the standard action, so a swap costs
    the move and the standard action and no more, and the log names the slot spent.
    The printed free draw combined with a regular move for base attack bonus +1 is
    still not granted. A two-handed weapon is refused while a shield is strapped on;
    the shield can now be loosed instead (entry 44). Threat no longer follows reach
    alone (entry 43). The shipped rogue is untouched: she still starts with her short
    sword readied and her light crossbow carried, and the fix is access to what she
    already owns, not a new item or feat.

43. **Threat requires a legal melee attack, not reach alone.** PHB printed p. 137
    says "You threaten all squares into which you can make a melee attack." The
    engine used to treat reach as sufficient, which let a crossbow-armed character
    take an opportunity attack with no melee weapon at all. Threat is now decided by
    `Encounter.melee_capability`: a readied weapon with a melee mode, a monster's
    natural attack, or the supported unarmed strike when both hands are empty. No
    improvised crossbow blow is invented, and a ranged-only readied weapon never
    threatens. The same test drives opportunity attacks, flanking, engagement for the
    shooting-into-melee penalty and provocation from casting or reloading, so the
    rules cannot disagree with each other. Engagement keeps the printed "either
    threatens the other" direction (p. 140): a crossbow-armed ally is still engaged
    when the enemy can strike back. Flat-footedness remains separate (p. 133): a
    flat-footed creature threatens but cannot react, and an unsupported reaction is
    refused with a reason without consuming the reaction. One deliberate divergence
    is recorded: printed 3.5 would let a bow-armed character make an unarmed strike,
    so a strict reading would still threaten; this build does not treat a
    ranged-only readied weapon as threatening, because it offers no legal melee
    attack and the alternative would be an invented improvised blow.

44. **Shields are strapped, carried, or dropped - and loosing means dropping.**
    PHB printed p. 142: "Strapping a shield to your arm to gain its shield bonus to
    your AC, or unstrapping and dropping a shield so you can use your shield hand for
    another purpose, requires a move action." The shield control lists the strapped
    shield and every shield in the pack; strapping one on moves it out of the pack
    into the shield slot, so its shield bonus, armor check penalty and proficiency
    rules apply through the existing AC path with no second copy. Loosing clears the
    slot and puts the shield on the ground on the character's square, where the
    existing Pick up action recovers it; it is never quietly stored in the pack, and
    no item is created or destroyed. A second shield cannot be strapped over the
    first, and a readied two-handed weapon blocks strapping one on. Only the two
    authored shields are supported: no buckler (whose loose action differs), no
    shield bash, no dual-wielding. The printed free ready-or-loose combined with a
    regular move is not granted; like the weapon entries it can spend the standard
    action as a move (p. 138).

45. **Correction, dated 2026-11-13: ordinary empty hands do not threaten.**
    Entry 43 above is kept as the historical record of how threat was first
    implemented. It was wrong on one point: it treated the unarmed strike as an
    armed melee attack, so a character with both hands empty threatened squares,
    contributed flanking, counted as engaged in melee and could take opportunity
    attacks. PHB printed p. 137 says plainly: "If you're unarmed, you don't
    normally threaten any squares and thus can't make attacks of opportunity (but
    see Unarmed Attacks, page 139)." Printed p. 139 repeats that "An unarmed
    character can't take attacks of opportunity" and defines which unarmed
    attacks are armed: "A monk, a character with the Improved Unarmed Strike feat,
    a spellcaster delivering a touch attack spell, and a creature with claws,
    fangs, and similar natural physical weapons all count as being armed." The
    code now separates three things instead of deriving all of them from one
    permissive test: `available_melee_attack` is the attack a combatant could
    attempt (a melee weapon, a natural weapon, or a plain unarmed strike);
    `threat_capability` is the armed state that threatens squares (melee weapon,
    natural weapon, or Improved Unarmed Strike with empty hands); and reaction
    eligibility remains the separate guard in `_provoke_single_opportunity`
    (capable, able to act, not flat-footed, not already used this round). Empty
    hands therefore grant no threat, no flanking, no engagement and no reaction,
    while natural weapons and genuinely armed unarmed attacks keep all of them.
    The earlier rationale is also withdrawn: the ability to attempt an unarmed
    strike while holding a bow is not a reason to grant threat, and the bow-held
    unarmed strike is not presented as the only difference from the printed rules.
    Two limits are stated rather than hidden: no monk class exists in this
    content, so the monk clause is unreachable, and a touch-spell delivery is not
    an attack this build performs, so that clause is unreachable too. Improved
    Unarmed Strike is recognised by feat text for the armed status only; its
    damage and nonlethal rules remain unimplemented and are the next milestone.

46. **Ordinary unarmed attacks added, dated 2026-11-13.** Entry 45 left the
    strike attemptable but semantically empty; this entry gives it the printed
    damage behavior without changing the threat split. PHB p. 139 supplies the
    rules used: "All damage from unarmed strikes is nonlethal damage", the size
    table (1d3 Medium, 1d2 Small, 1d4 Large), the light/inherently
    non-proficient status of the strike, and the provocation sentence: an
    unarmed attack provokes an attack of opportunity from the armed defender it
    targets (not from unarmed bystanders). Implementation: `Character.nonlethal`
    plus `apply_nonlethal` keep nonlethal damage in its own total, unconscious
    when it exceeds current hit points, persisted in the save record;
    `Rules.nonlethal_immune` covers undead and constructs, whose type traits
    grant the immunity; `Encounter._unarmed_strike` builds the size-based attack
    so the ordinary Attack action always has a melee option;
    `Encounter._apply_damage` sends nonlethal results to the separate total,
    logs immunity, and leaves hit points untouched; the nonlethal flag is
    carried through single attacks, opportunity attacks and the monster full
    attack so a provoked unarmed strike also deals nonlethal damage.
    Adaptations stated rather than hidden: (a) the lethal-at-−4 alternative is
    not offered, so every unarmed strike is nonlethal; (b) Improved Unarmed
    Strike is recognised for armed status and for the printed no-provocation
    clause (its unarmed attacks draw no reaction), but its improved damage
    (1d6 Medium and so on) is not implemented, so a feat-holder still rolls the
    ordinary size-based die; (c) the nonlethal total is only
    reduced by the existing rest path, not by a dedicated "recover" control;
    (d) no monk and no touch-spell delivery exist, so those p. 139 clauses stay
    unreachable. Nonlethal damage is not a prerequisite for threat and was not
    added to repair threat: the threat split in entry 45 stands on its own, and
    this unit was chosen only after that correction was verified in an exported
    executable.

47. **Correction and completion, dated 2026-11-13: the Improved Unarmed Strike
    record and the nonlethal state machine.** Entry 46 stated a limitation that
    does not exist in the printed feat: "Improved Unarmed Strike's improved damage
    die". PHB printed p. 97 says nothing about a damage die. Its benefit is
    threefold: "You are considered to be armed even when unarmed - that is, you do
    not provoke attacks of opportunity from armed opponents when you attack them
    while unarmed. However, you still get an attack of opportunity against any
    opponent who makes an unarmed attack on you. In addition, your unarmed strikes
    can deal lethal or nonlethal damage, at your option." The normal rule is the
    opposite: "Without this feat, you are considered unarmed when attacking with
    an unarmed strike, and you can deal only nonlethal damage with such an
    attack." Increased unarmed damage belongs to the monk class feature, not to
    this feat, and no monk exists in this content, so no damage progression is
    added. The implementation already granted armed status and the no-provocation
    clause; this unit adds the lethal/nonlethal choice through the existing attack
    controls. A character with the feat may choose lethal damage with no penalty;
    a character without it may still choose lethal damage, but takes the printed
    -4 (PHB p. 147, "Lethal Damage with a Weapon that Deals Nonlethal Damage").
    Entry 46's statements that "the lethal-at--4 alternative is not offered" and
    that the feat's damage is "not implemented" are superseded by this entry; the
    rest of entry 46 (nonlethal totals, provocation, immunity, persistence)
    stands.

    Nonlethal state, verified against printed p. 147: nonlethal damage is a
    running total that is never deducted from hit points; it is compared with
    *current* hit points, so "it doesn't matter whether the nonlethal damage
    equals or exceeds your current hit points because the nonlethal damage has
    gone up or because your current hit points have gone down." Equality means
    staggered - "you can only take a standard action or a move action in each
    round" - and a greater total means unconscious and helpless. The state is
    derived on every change (nonlethal gain, hit-point loss, healing, rest, load)
    and uses its own effect ids (`staggered`, `nonlethal_unconscious`) so clearing
    it can never erase dying, paralysis, death or a spell's unconsciousness. Zero
    nonlethal damage never creates a state, so a character at 0 hit points with no
    nonlethal damage stays disabled rather than becoming "staggered" by a 0 = 0
    comparison. Staggered characters still take their turn; the encounter refuses
    a standard action after a move and a move after a standard action, and the
    combat screen disables the same controls. An enemy that is dead or unconscious
    no longer keeps the encounter alive, so knocking every enemy out wins the
    fight (unconscious creatures are helpless, not fighting).

    Magical healing, printed p. 147: "When a spell or a magical power cures hit
    point damage, it also removes an equal amount of nonlethal damage." The
    supported magical sources - cure light wounds, a potion of cure light wounds
    drunk in combat or from the inventory, and the authored "wave of healing"
    effect - now call `Character.magical_heal`, which heals hit points and removes
    up to the same amount of nonlethal damage. The removal is keyed to the amount
    the effect cures, not to the hit points actually restored, so a full-hit-point
    target with nonlethal damage still benefits. Natural recovery is a separate
    printed rule ("1 hit point per hour per character level"); there is no elapsed-
    hour model, so a full night's rest clears the nonlethal total outright (8 hours
    at 1/level/hour exceeds any total this content can generate) and that
    substitution is recorded here rather than presented as printed hourly
    tracking.

    Artifact identity: the earlier note that the source tree was "older than the
    binary" is withdrawn as evidence. `builds/qa/candidates/unarmed_2026-11-13/ARTIFACT_NOTE.txt`
    records that an intermediate export in that directory was overwritten and is
    not preserved; the surviving binary is identified by its full SHA-256, its
    `BUILD.txt` record and its source snapshot. Every evidence export now gets a
    new directory or an explicit attempt suffix.

48. **Encounter resolution, dated 2026-11-13: temporary incapacity is not defeat.**
    Entry 47 said that "an enemy that is dead or unconscious no longer keeps the
    encounter alive", and the implementation tested `Character.can_act()` on both
    sides. That test is too broad. Ghoul paralysis lasts 1d4+1 rounds (MM p. 119)
    and a timed unconsciousness effect also ends by itself; both make a creature
    unable to act, yet neither is printed defeat. Under `can_act()` a party that
    paralysed every enemy won the fight, with XP, victory narration and campaign
    effects, while the enemies were still alive and would recover; a party that
    was wholly paralysed suffered an immediate defeat. Resolution now names the
    states instead of reusing one predicate: an enemy is out of the fight for good
    only when it is dead/destroyed or nonlethally unconscious (nonlethal total
    above current hit points, helpless per PHB p. 147), and the party is defeated
    only when every member is dead, dying, stable or nonlethally unconscious. A
    wholly paralysed party keeps the encounter running with its turns skipped and
    resumes when the paralysis expires. No surrender, capture or morale subsystem
    is added, and the nonlethal victory path of entry 47 is unchanged.

49. **Class progression lives in code, and the authored level-3 differences stay
    accepted.** The five classes' levels 1-4 (hit die, skill points, base attack,
    base saves, feat slots, printed spell slots and sorcerer spells known) live in
    `ClassProgression.CLASSES` beside the other rules catalogs rather than in content
    JSON. Reason: rules, the diagnostics validator and the tests must agree on the
    same numbers, and one typed constant cannot drift between three readers; content
    schemas are unchanged, so an editable class list can still replace it if a
    data-driven campaign needs one. The table was checked against the printed pages
    before it was written (Table 3-1 and 3-2 p. 22; Table 3-6 p. 31; Table 3-9
    p. 39; Table 3-15 p. 49; Table 3-16 p. 52; Table 3-17 p. 54; Table 3-18
    p. 55); the fighter, sorcerer and wizard page numbers in the plan were wrong
    and were corrected there. Nothing reads the table for play yet, so no character,
    save, XP, level, UI or rules value moved. Thirteen differences between the
    tables and the authored level-3 party are accepted rather than repaired,
    because this batch may not change derived numbers: four feat lists below their
    printed slots; three cross-class ranks above the level-3 cap (sense motive,
    search, diplomacy) with the resulting point totals over the class budget;
    Ysolde's +1 1st and +1 2nd slots from Intelligence 17; Mira's 1st-level slots at
    the printed 4th-level count with a known list missing the 0-level spells and one
    1st-level spell; and the engine's absent 0-level row for every caster.
    `authored_inconsistencies()` and `--validate-diagnostics` print them on every
    run so they stay visible instead of being silently blessed; a later
    content-audit batch may fix them.

50. **Level-up treats authored gaps as authored, and the thirteen level-3
    differences are decided one by one.** Section 11.2 of `LEVEL_UP_PLAN.md`
    records the decision for each batch-1 finding. Carried forward: the four feat
    lists below their printed slots (adding feats would change attack, AC, saves or
    skills, which is a balance change, not a correction; level-up grants only the
    new fighter slot), Ysolde's +1 1st and +1 2nd slots (the authored
    representation of her Int 17 bonus, since the engine has no bonus-spell model),
    Mira's six 1st-level slots (her row already equals the printed 4th-level
    count), and her short known list. Repaired later in one separate content commit
    that touches no engine code: the three cross-class ranks above the level-3 cap
    (sense motive, search, diplomacy) and the two skill-point overspends, by
    rebuilding aldric's and mira's rank blocks inside their 12-point budgets and
    lowering ysolde's search to 3. Existing saves keep their stored ranks; there is
    no migration. Level-up itself never audits or clamps an existing rank: it adds
    exactly one 2nd-level spell to Mira (no 0-level, no 1st-level back-fill), adds
    the level-4 slot deltas cleric +1/+1, wizard +1/+1 and sorcerer 2nd-level 3 with
    the 1st level unchanged at 6, and applies the caps at level 4 (class 7,
    cross-class 3) only to points spent during the step. The level-4 sorcerer row
    therefore ends at 6/3, matching the book, while the wizard row keeps its
    authored Int bonus. A raising of Constitution recomputes HP from all four levels
    rather than adding an average twice.

51. **Level-up core is engine-only, and its 4th-level skill caps, point costs and
    slot deltas are explicit.** Batch 2 adds `LevelUp` with no caller in play. The
    printed skill rule (SRD Skills Summary; PHB p. 62) gives a class cap of
    character level + 3 (7 at 4th) and a cross-class cap of half that number,
    "do not round up or down" (3.5 at 4th); each skill point buys 1 class rank or
    1/2 cross-class rank, and half ranks do not improve a check. The engine stores
    whole ranks only and charges 2 points per cross-class rank, so the enforceable
    cross-class cap is 3 whole ranks; `Skills.max_ranks` already floors and is used
    on the staged level-4 character. A 4th cross-class rank is refused, and the
    unrepresentable half is recorded here rather than presented as printed. The
    ability increase is applied before HP, saves and the skill budget; HP is
    recomputed from all four hit dice and the new Constitution modifier, and
    current damage is preserved rather than current HP; the authored level-3 rows
    gain the explicit deltas cleric +1/+1, wizard +1/+1 and sorcerer 2nd-level 3
    with 1st-level unchanged at 6, so Mira ends on the printed 6/3 and Ysolde keeps
    her Intelligence bonus. The sorcerer's known list gains exactly one 2nd-level
    spell, with no 0-level or 1st-level back-fill. Existing ranks above the new
    cap are shown as a notice and are never audited or clamped. XP is a gate and is
    never spent; a second apply refuses and changes nothing; old saves load without
    migration and never level on load.

52. **The five authored skill findings are repaired in content, not by
    migration.** The separate repair commit rebuilds aldric's and mira's rank
    blocks inside the level-3 budget and lowers ysolde's search to the
    cross-class cap; no other field moves and no save is rewritten. Aldric goes
    from heal 6, diplomacy 4, sense motive 4, listen 2, spot 2 (26 of 12
    points) to diplomacy 2, heal 4, sense motive 3 (12 of 12). Sense motive 3
    costs six of his twelve points at two per cross-class rank, so keeping heal
    at 6 and diplomacy at 4 as well was arithmetically impossible; the two
    class skills are funded first and listen and spot are dropped, with party
    perception left to Sera and Ysolde. Mira goes from search 2, spot 2,
    listen 2, diplomacy 4 (20 of 12) to bluff 2, diplomacy 3, search 1,
    spellcraft 2 (12 of 12), which adds the sorcerer class skills the decision
    asked for. Ysolde only moves search 4 -> 3 (20 -> 18 of 30). The accepted
    inconsistency set falls from thirteen to eight; the four feat counts, the
    two Int bonus-slot readings and Mira's slot and known-list readings stay
    accepted. Existing saves keep their stored ranks, so no character is
    rewritten mid-campaign.

53. **The fighter's printed bonus-feat markers live in Table 5-1, and the
    implemented catalog is the selection surface.** PHB p. 38 requires the bonus
    feats to be "drawn from the feats noted as fighter bonus feats on Table 5-1:
    Feats (page 90)" and to meet all their prerequisites; Table 5-1, printed
    pp. 90-91, marks them with footnote 1, "A fighter may select this feat as one
    of his fighter bonus feats." `Feats.CATALOG` now stores `fighter_bonus` on
    every entry: ten of the 41 implemented feats are marked (Cleave, Combat
    Expertise, Dodge, Exotic Weapon Proficiency, Improved Trip, Point Blank Shot,
    Precise Shot, Power Attack, Weapon Finesse, Weapon Focus), and feats the table
    does not mark stay selectable only as general feats - notably Improved
    Initiative, Toughness, Skill Focus and the armor, shield and weapon
    proficiency feats. Printed fighter feats this slice does not implement (Weapon
    Specialization, Improved Bull Rush, Quick Draw, Two-Weapon Fighting and others)
    are absent from the picker and are a deferred content gap, not a silent
    substitution. Parameterized feats use the content id as their parameter, so a
    Skill Focus row reads "Skill Focus (search)" while the engine looks the skill
    up by id; a weapon the table does not call exotic stays listed for Exotic
    Weapon Proficiency with the reason `Feats` already returns. The choice data is
    a second reader of `LevelUp.stage`, and `apply` remains the only path that
    changes a character.
54. **The level-up screen presents the existing choices; it decides nothing.** Three
    presentation decisions are recorded here so a later reader does not mistake them
    for rules. First, the button lives on a party-sheet *page*, not on a card: the
    sheet is a `TabContainer` with one scrolling page per party member
    (`src/ui/panels.gd:22`), so "one button per character" means one button in each
    page's header, built only when `LevelUp.eligibility` says yes - an ineligible page
    shows the reason instead of a disabled button. Second, the step list is derived
    from the choice data, not fixed: Summary, Ability, Skills and Confirm always, Feat
    when the character has a fighter bonus-feat slot, Spells when there is a spell
    choice, so a rogue sees four steps and a fighter or sorcerer five. The printed
    rules do not prescribe a dialog; the steps only group the choices `LevelChoices`
    already returns, and no step can offer something the module does not. Third, the
    keyboard path is Tab, Shift+Tab, Enter, Space, Esc and the page keys only: the
    modal's arrow keys scroll its body (`src/main.gd:8031`), so a `SpinBox` or
    `OptionButton` row would change meaning between 100 % and 160 %. Skill points are
    therefore spent one rank per row press, with a reset, and unspent points are
    discarded by `LevelUp.apply` - the engine's existing rule (`LEVEL_UP_PLAN.md` 12.5),
    not a new one. Confirm is the only place that changes a character, it asks
    `LevelChoices.validate` first, and on a refusal it keeps the dialog open with the
    engine's own message. `LevelUp.stage` stays out of the UI entirely.

55. **The level-up refusal lands on the step that owns it, and the modal owns its
    own close.** Two decisions taken while implementing 4a, recorded because they
    are not in the plan's first wording. First, `LEVEL_UP_PLAN.md` 14.4 said a
    refused Confirm *stays on Confirm* and moves focus to the refused group; in
    practice a refused group's rows live on another step, so a missing fighter feat
    had no control to focus on Confirm at all. The modal now moves to the step that
    owns the refusal - Feat, Spells, Skills or Ability - keeps the engine's message
    in the refusal line above the footer, and focuses the first row of that group
    the player can actually choose. The modal stays open, the draft is untouched and
    `LevelUp.apply` is still not reached, which is what the plan's own test pins.
    Second, the `modal` field is singular, so the level-up modal replaces the party
    sheet's modal instead of stacking on it. `src/main.gd` gained one one-shot
    callback, `modal_on_close`, which `close_modal` runs once and which
    `open_modal`'s replacement path never runs, so Cancel, the header `Close (Esc)`
    and Esc all put the sheet back on the same page with the `Level up` button
    focused without a second dismissal path. The stale-page test also showed that
    `LevelChoices.validate` reports the staging code (`feat_already_owned` and so
    on) rather than `already_level_4` for a character who has already taken the
    step, because it stages instead of applying. The screen still refuses and
    writes nothing; the disagreement with `validate`'s own doc comment is recorded
    as an open defect in `LEVEL_UP_PLAN.md` 14.11 rather than repaired in 4a,
    because repairing it changes a batch-3 refusal code.

56. **`validate` asks eligibility before it judges a choice.** The defect recorded in
    entry 55 is repaired in its own commit: `LevelChoices.validate` now returns
    `LevelUp.eligibility`'s code and message before it stages anything, so a spent
    step, a character below the threshold, one not at 3rd level and one with no class
    table are refused with the same code and message `LevelUp.apply` gives. Nothing
    printed moved and no rule changed; the screen still asks `validate` first and
    `LevelUp.apply` is still the only writer. Entry 55's note that the disagreement
    was recorded rather than repaired no longer applies, and the same fix removes a
    script error: `LevelUp.stage` indexes the class table directly, so `validate` used
    to crash on an untabled class instead of reporting `class_not_tabled`.

57. **End scrolls a modal body, and C5 is read as the scrolling rows.** Two adjustments
    in 4c, both recorded rather than applied silently. `End` now jumps a modal body to
    its last row: `LEVEL_UP_PLAN.md` 14.5 promised it beside PageDown, the handler never
    read `ui_end`, and the level-up screen needed it to reach the last skill row without
    tabbing through 46 of them. And C5 of 14.6 - "every focusable in
    `_modal_focusables()`" - is read as the rows inside the step's scrolling pane,
    because C3 requires the footer to sit outside that pane and the header `Close` is
    not part of the body; the header and footer are held by C2 and C3 instead. No rule
    or printed value is involved in either.
58. **The bell pays a 2,300 XP completion milestone (batch 6a).** The demo could not
    reach 4th level: 2,200 authored XP against the printed 6,000 (PHB Table 3-2,
    p. 22), and its best single ordinary route carried 1,850. DMG pp. 39-40 allow
    experience for goals other than defeated monsters and give no number for them,
    so the amount is a project adaptation, not a printed value. 2,300 is derived
    from the least-awarding route that completes `drowned_bell` - crate 0 + Corvin's
    pact 200 + bell 500 = 3,700 - so every completing player is eligible when the
    quest completes, at 6,000 exactly; the named combat route lands at 6,550. 1,750
    was rejected because it leaves the parley route at 5,750 at the bell. The award
    sits on the bell rather than on a quest hook because the engine has no XP hook
    for quest completion, the bell is where `bell_rung` - the last objective - is
    set, and the interaction boundary autosaves what it pays. A player who rings
    without resolving the warden is at 5,800 and has not completed the quest, since
    `warden_resolved` is an objective: the least-awarding *completion* is 3,000 with
    the milestone (700 without it), not a floor for every route that rings. No
    threshold, encounter, character, UI, schema or save changed.
59. **The advancement inventory classifies by reference, not by map tile (batch
    6b).** `--validate-diagnostics` now prints one `ADVANCEMENT AWARDS` line per
    campaign: `authored`, `ordinary`, `qa`, `encounters`, `effects`, `start` and
    `threshold`. An encounter counts as ordinary when any shipped trigger or
    `start_combat` effect names it, and as QA-only only when nothing in the content
    does; a closure keeps an encounter that only a QA-only encounter starts on the
    QA side. The alternative - "has a map trigger" - was rejected because it
    misclassifies `crypt_warden`, which has no trigger at all and is entered from
    Corvin's dialogue. `start` is the lowest authored XP among the default party,
    because the threshold is per character and the line carries one number.
    `effects` counts every authored `xp` effect, including an encounter's victory
    effects, while an encounter's own `xp` field is counted once as an encounter
    award. The line is informational: it never becomes a diagnostic, a campaign
    below the threshold still passes, and the JSON diagnostics contract is
    byte-identical before and after.

60. **Completability spends the whole skill budget, and an empty character fails
    the validator (batch 6c).** The plan's check staged a draft with
    `skills: {}`, but the engine accepts an underspent budget, so an empty draft
    would have proved less than it claimed. The check therefore allocates the whole
    budget - class skills first, one rank at a time, inside the caps - and accepts
    only a stage whose `spent` equals its `budget`; a character whose budget cannot
    be spent is reported, not passed. The search is exhaustive over the six
    abilities and over the screen's own feat and spell candidate lists, with one
    deterministic allocation per combination, because skill legality depends only on
    the budget (class points plus the Int modifier after the increase) and the caps,
    neither of which depends on the feat or the spell. An empty shipped character is
    a validation failure naming the group that emptied, as the plan decided; today
    all five pass. Staging goes through `LevelChoices.stage_completed` because
    `validate` asks eligibility first and would refuse every shipped character, and
    because the batch-3 guard keeps `LevelUp.stage` inside the choice module. The
    inherited 6b question is answered: a prose mention of an encounter id cannot be
    counted as an ordinary reference, because classification reads trigger fields and
    `start_combat` effects only.
