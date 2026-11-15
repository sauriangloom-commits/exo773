class_name Dice
extends RefCounted

## Deterministic dice helpers.
##
## Every random roll in the game flows through an injected
## [RandomNumberGenerator] so tests can seed it and replays are possible.
## Dice expressions use the tabletop form: "d20", "2d6+3", "1d8-1".

const MAX_DICE := 100


static func roll(rng: RandomNumberGenerator, count: int, sides: int) -> int:
	var total := 0
	var n: int = clampi(count, 0, MAX_DICE)
	var s: int = maxi(sides, 1)
	for _i in n:
		total += rng.randi_range(1, s)
	return total


static func roll_detail(rng: RandomNumberGenerator, count: int, sides: int) -> Dictionary:
	var rolls: Array[int] = []
	var n: int = clampi(count, 0, MAX_DICE)
	var s: int = maxi(sides, 1)
	for _i in n:
		rolls.append(rng.randi_range(1, s))
	var total := 0
	for r in rolls:
		total += r
	return {"rolls": rolls, "total": total, "count": n, "sides": s}


static func d20(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 20)


static func percent(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 100)


## Parses one of: "12", "d20", "1d8", "2d6+3", "1d4-1".
## Returns {total, rolls, modifier, expression, valid}.
static func parse(rng: RandomNumberGenerator, expression: String) -> Dictionary:
	var expr := expression.strip_edges().to_lower()
	var re := RegEx.new()
	re.compile("^(\\d*)d(\\d+)([+-]\\d+)?$")
	var result := {
		"expression": expression,
		"rolls": [] as Array[int],
		"modifier": 0,
		"total": 0,
		"valid": false,
	}
	if expr == "":
		return result
	var m := re.search(expr)
	if m != null:
		var count_txt := m.get_string(1)
		var count: int = 1 if count_txt == "" else int(count_txt)
		var sides := int(m.get_string(2))
		var modifier := 0
		if m.get_string(3) != "":
			modifier = int(m.get_string(3))
		var detail := roll_detail(rng, count, sides)
		result["rolls"] = detail["rolls"]
		result["modifier"] = modifier
		result["total"] = int(detail["total"]) + modifier
		result["valid"] = true
		return result
	if expr.is_valid_int():
		result["total"] = int(expr)
		result["valid"] = true
	return result


## Rolls an expression and returns only the total. Invalid expressions roll 0.
static func expression(rng: RandomNumberGenerator, expression: String) -> int:
	return int(parse(rng, expression)["total"])


static func describe(parsed: Dictionary) -> String:
	var rolls: Array = parsed.get("rolls", [])
	var modifier := int(parsed.get("modifier", 0))
	if rolls.is_empty():
		return str(parsed.get("total", 0))
	var parts: Array[String] = []
	for r in rolls:
		parts.append(str(r))
	var text := "[" + ", ".join(parts) + "]"
	if modifier != 0:
		text += ("%+d" % modifier)
	return text
