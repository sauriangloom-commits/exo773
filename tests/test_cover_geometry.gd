extends GutTest

## Creature soft cover (PHB p. 151): "choose a corner of your square. If any line
## from this corner to any corner of the target's square passes through a square
## or border that blocks line of effect or provides cover, or through a square
## occupied by a creature, the target has cover (+4 to AC)."
##
## These tests pin the geometry only - no attack, no encounter. They are the
## executable record of the grid adaptations in docs/ADAPTATION_LOG.md:
##
## 1. A creature covers a line only when the line crosses its square's interior.
##    A line that shares an edge or a corner with the square does not count,
##    because otherwise two allies in one row would block every line along their
##    shared border and a diagonal neighbour would always grant cover.
## 2. The attacker chooses the corner, so one clear corner is enough to shoot
##    past an intervening creature.
##
## Wall cover, low walls, reach melee and concealment stay out of scope.

func _occupied(cells: Array) -> Dictionary:
	var out := {}
	for cell in cells:
		out[cell] = true
	return out


func _cover(attacker: Vector2i, target: Vector2i, blockers: Array) -> int:
	return BattleMap.creature_cover(attacker, target, _occupied(blockers))


func test_a_creature_between_attacker_and_target_grants_cover() -> void:
	assert_eq(
		_cover(Vector2i(1, 1), Vector2i(3, 1), [Vector2i(2, 1)]),
		4,
		"a creature in the straight line grants +4 AC",
	)


func test_a_creature_away_from_every_line_grants_nothing() -> void:
	assert_eq(
		_cover(Vector2i(1, 1), Vector2i(3, 1), [Vector2i(2, 3)]),
		0,
		"a creature off the line is not cover",
	)


func test_a_creature_adjacent_to_the_attacker_still_grants_cover() -> void:
	# No printed exception for a creature next to the shooter; soft cover is
	# "creatures, even your enemies".
	assert_eq(
		_cover(Vector2i(0, 0), Vector2i(2, 0), [Vector2i(1, 0)]),
		4,
		"adjacency to the attacker does not remove cover",
	)


## The case a centre-to-centre line misses. Attacker (0,0), target (3,3) and a
## creature at (2,3): the centre line visits (1,1), (2,2), (3,3) and never the
## creature, but the attacker's corner line to the target's corner (3,4) passes
## through the creature's square.
func test_a_corner_line_grants_cover_the_centre_line_misses() -> void:
	var centre := BattleMap.cells_crossed(Vector2(0.5, 0.5), Vector2(3.5, 3.5))
	assert_false(
		centre.has(Vector2i(2, 3)),
		"the centre line does not cross the creature, so centre-to-centre would say no cover",
	)
	assert_true(
		BattleMap.cells_crossed(Vector2(1.0, 0.0), Vector2(3.0, 4.0)).has(Vector2i(2, 3)),
		"the printed corner line does cross the creature",
	)
	assert_eq(
		_cover(Vector2i(0, 0), Vector2i(3, 3), [Vector2i(2, 3)]),
		4,
		"the printed rule grants cover where centre-to-centre would not",
	)


## One clear corner is enough: the attacker chooses the vantage point.
func test_one_clear_corner_shoots_past_a_creature_behind_the_target() -> void:
	assert_eq(
		_cover(Vector2i(0, 0), Vector2i(3, 3), [Vector2i(0, 3)]),
		0,
		"a creature screened off to the target's left leaves the right corners clear",
	)


func test_the_attacker_and_target_squares_are_never_cover() -> void:
	assert_eq(
		_cover(Vector2i(1, 1), Vector2i(3, 1), [Vector2i(1, 1)]),
		0,
		"the attacker's own square is not cover",
	)
	assert_eq(
		_cover(Vector2i(1, 1), Vector2i(3, 1), [Vector2i(3, 1)]),
		0,
		"the target's own square is not cover",
	)


func test_cover_does_not_stack() -> void:
	assert_eq(
		_cover(Vector2i(1, 1), Vector2i(4, 1), [Vector2i(2, 1), Vector2i(3, 1)]),
		4,
		"two creatures still give one +4, not +8",
	)


func test_a_creature_at_the_targets_shoulder_grants_cover() -> void:
	# Alongside the target rather than strictly between: the corner fan still
	# clips it, which is what the printed rule does on a grid.
	assert_eq(
		_cover(Vector2i(1, 4), Vector2i(4, 1), [Vector2i(3, 1)]),
		4,
		"a creature beside the target screens one of its corners",
	)


# --------------------------------------------------------------- the geometry

func test_a_segment_along_a_grid_line_touches_no_square() -> void:
	assert_eq(
		BattleMap.cells_crossed(Vector2(1.0, 0.0), Vector2(3.0, 0.0)).size(),
		0,
		"a line running along a border lies in no square's interior",
	)


func test_a_diagonal_through_a_corner_enters_only_the_diagonal_square() -> void:
	var cells := BattleMap.cells_crossed(Vector2(0.0, 0.0), Vector2(2.0, 2.0))
	assert_true(cells.has(Vector2i(1, 1)), "the diagonal square is crossed")
	assert_false(cells.has(Vector2i(1, 0)), "the square above the corner is not")
	assert_false(cells.has(Vector2i(0, 1)), "the square beside the corner is not")


func test_a_straight_segment_reports_every_square_it_crosses() -> void:
	var cells := BattleMap.cells_crossed(Vector2(0.5, 0.5), Vector2(3.5, 0.5))
	for expected in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
		assert_true(cells.has(expected), "the segment crosses %s" % str(expected))
	assert_false(cells.has(Vector2i(0, 1)), "it does not enter the next row")


func test_an_identical_cell_is_not_cover_for_itself() -> void:
	assert_eq(
		BattleMap.creature_cover(Vector2i(2, 2), Vector2i(2, 2), _occupied([Vector2i(3, 2)])),
		0,
		"a zero-length shot has no cover",
	)


func test_an_empty_board_grants_no_cover() -> void:
	assert_eq(
		BattleMap.creature_cover(Vector2i(1, 1), Vector2i(4, 1), {}),
		0,
		"no creatures means no cover",
	)
