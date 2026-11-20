class_name SaveMigrations
extends RefCounted

## Read-only upgrade path for save payloads.
##
## `SaveSystem.SAVE_VERSION` is still 1 and `steps` ships empty, so no production
## save is migrated and every refusal behaves exactly as it did. The foundation is
## here so the first real schema change (roadmap P0 item 4) is a table row plus a
## fixture, not a rewrite of the loader.
##
## A step is a pure `Dictionary -> Dictionary` function, keyed by the version it
## upgrades *from*: `steps[1]` turns a version 1 payload into version 2. It must
## copy its input (unknown fields survive a migration so a newer build's data is
## not silently dropped) and return `null` when it cannot honestly upgrade, which
## keeps the player-facing refusal instead of producing a half-migrated save.
##
## Tests install synthetic steps here and restore the table afterwards; nothing in
## production registers one until that schema change actually ships.

static var steps: Dictionary = {}

## Oldest version this build can bring forward. Anything older is refused as too
## old rather than upgraded by guesswork, and anything newer than the target is
## refused as incompatible (there is no downgrade path).
const SUPPORTED_MIN_VERSION := 1

## Tests raise this to exercise the read path with synthetic steps while
## `SaveSystem.SAVE_VERSION` stays 1. Production leaves it at 0, which means "use
## SaveSystem.SAVE_VERSION"; nothing in the game writes to it.
static var target_override := 0


## The upgraded payload, or `null` when it cannot be brought to `target`.
##
## Returns a copy in every case, so a caller can never mutate the parsed file by
## accident. Never touches the disk: a migrated save is written only when the
## player saves again, which keeps a refused or interrupted save from rewriting
## the original file.
static func upgrade(data: Dictionary, from: int, target: int) -> Variant:
	if from == target:
		return data.duplicate(true)
	if from < SUPPORTED_MIN_VERSION or from > target:
		return null
	var current: Dictionary = data.duplicate(true)
	var version := from
	while version < target:
		var step: Callable = steps.get(version, Callable())
		if not step.is_valid():
			return null
		var next: Variant = step.call(current.duplicate(true))
		if not next is Dictionary:
			return null
		current = next
		version += 1
	return current
