class_name CampaignDB
extends RefCounted

## Registry of installed campaign packages.
##
## A campaign is data, not code: `content/campaigns/<id>/campaign.json` plus the
## campaign's own story tables (areas, dialogue, quests, encounters, narration).
## Shared rules content (items, spells, characters, monsters) lives once in
## `content/shared`. Loading a campaign never edits the project.

const CAMPAIGNS_ROOT := "res://content/campaigns"
const REGISTRY_PATH := "res://content/campaigns/_registry.json"
const FORMAT_VERSION := 1

var campaigns: Dictionary = {}  # id -> manifest Dictionary
var order: Array[String] = []
var default_id := ""
var errors: Array[String] = []


func load_registry() -> void:
	campaigns.clear()
	order.clear()
	errors.clear()
	default_id = ""
	if not FileAccess.file_exists(REGISTRY_PATH):
		errors.append("Missing campaign registry: %s" % REGISTRY_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	if not parsed is Dictionary:
		errors.append("Campaign registry is not valid JSON.")
		return
	var registry: Dictionary = parsed
	var format_version := int(registry.get("format_version", 0))
	if format_version != FORMAT_VERSION:
		errors.append(
			"Campaign registry format version %d is not supported (expected %d)."
			% [format_version, FORMAT_VERSION]
		)
	var listed: Variant = registry.get("campaigns", [])
	if not listed is Array or Array(listed).is_empty():
		errors.append("Campaign registry lists no campaigns.")
		return
	for raw_id in Array(listed):
		var campaign_id := String(raw_id)
		if campaign_id == "":
			errors.append("Campaign registry contains an empty campaign id.")
			continue
		if campaigns.has(campaign_id):
			errors.append("Duplicate campaign id '%s' in the registry." % campaign_id)
			continue
		var manifest := _read_manifest(campaign_id)
		if manifest.is_empty():
			continue
		campaigns[campaign_id] = manifest
		order.append(campaign_id)
	_load_user_campaigns()
	default_id = String(registry.get("default", ""))
	if default_id == "":
		default_id = order[0] if not order.is_empty() else ""
	elif not campaigns.has(default_id):
		errors.append("Campaign registry default '%s' is not installed." % default_id)
		default_id = order[0] if not order.is_empty() else ""


## User-authored packages are discovered by scanning user://campaigns, so a new
## campaign never needs an engine or registry edit. An id that collides with a
## bundled package is rejected rather than shadowing it.
func _load_user_campaigns() -> void:
	# A package that cannot be read is skipped by discovery; its explanation is
	# carried into this registry's errors so the validator, the creator and the
	# player's log can say why the campaign is missing instead of it vanishing.
	var user_manifests := CampaignStore.list_user_campaigns()
	for scan_error in CampaignStore.scan_errors:
		errors.append(scan_error)
	for manifest in user_manifests:
		var entry: Dictionary = manifest
		var campaign_id := String(entry.get("id", ""))
		if campaign_id == "":
			continue
		if campaigns.has(campaign_id):
			errors.append(
				"User campaign '%s' collides with an installed campaign. Rename its folder and id."
				% campaign_id
			)
			continue
		if int(entry.get("format_version", 0)) != FORMAT_VERSION:
			errors.append(
				"User campaign '%s' uses unsupported format version %s."
				% [campaign_id, entry.get("format_version", "?")]
			)
			continue
		if String(entry.get("title", "")).strip_edges() == "":
			errors.append("User campaign '%s' has no title." % campaign_id)
			continue
		entry["source"] = "user"
		entry["writable"] = true
		entry["package_dir"] = CampaignStore.package_dir(campaign_id)
		campaigns[campaign_id] = entry
		order.append(campaign_id)


func get_campaign(campaign_id: String) -> Dictionary:
	var value: Variant = campaigns.get(campaign_id, {})
	return Dictionary(value).duplicate(true) if value is Dictionary else {}


func has(campaign_id: String) -> bool:
	return campaigns.has(campaign_id)


func _read_manifest(campaign_id: String) -> Dictionary:
	var path := CAMPAIGNS_ROOT.path_join(campaign_id).path_join("campaign.json")
	if not FileAccess.file_exists(path):
		errors.append("Campaign '%s' has no campaign.json." % campaign_id)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("Campaign '%s' manifest is not valid JSON." % campaign_id)
		return {}
	var manifest: Dictionary = Dictionary(parsed).duplicate(true)
	manifest["source"] = "bundled"
	manifest["writable"] = false
	manifest["package_dir"] = CAMPAIGNS_ROOT.path_join(campaign_id)
	var declared := String(manifest.get("id", ""))
	if declared != campaign_id:
		errors.append(
			"Campaign folder '%s' declares id '%s'; folder and id must match."
			% [campaign_id, declared]
		)
		return {}
	var format_version := int(manifest.get("format_version", 0))
	if format_version != FORMAT_VERSION:
		errors.append(
			"Campaign '%s' uses format version %d; this build supports %d."
			% [campaign_id, format_version, FORMAT_VERSION]
		)
	if String(manifest.get("title", "")).strip_edges() == "":
		errors.append("Campaign '%s' has no title." % campaign_id)
	if String(manifest.get("description", "")).strip_edges() == "":
		errors.append("Campaign '%s' has no description." % campaign_id)
	if int(manifest.get("version", 0)) < 1:
		errors.append("Campaign '%s' has no positive content version." % campaign_id)
	# The content root is resolved here, not authored twice.
	if String(manifest.get("content_root", "")) == "":
		manifest["content_root"] = CAMPAIGNS_ROOT.path_join(campaign_id)
	return manifest
