class_name DiscoveryEntry
extends Resource
##
## A single mythic-scientific journal entry. Authored by hand.
## Instances live in data/discovery/<id>.tres.
##

@export var id: StringName = &""
@export var title: String = ""
@export var body: String = ""

# Category drives sectioning in the discovery-log UI and filters in the index.
# Recognized values:
#   &"kingdom"   — fired when a kingdom is first unlocked
#   &"niche"     — fired when a niche is first played
#   &"node"      — fired when an evolution node is first purchased
#   &"event"     — fired when an event first resolves (per-run dedup via run.event_first_fires_seen)
#   &"milestone" — fired by DiscoveryLog at hardcoded thresholds (5 prestiges, etc.)
@export var category: StringName = &""

# What triggers this entry. Semantics depend on category:
#   kingdom   → kingdom_id (e.g. &"fungi")
#   niche     → niche_id (e.g. &"parasitic_plantae")
#   node      → evolution node id (e.g. &"wood_wide_web")
#   event     → event_id (e.g. &"drought")
#   milestone → milestone id (e.g. &"prestige_5", &"first_cross_kingdom_node")
@export var trigger_id: StringName = &""
