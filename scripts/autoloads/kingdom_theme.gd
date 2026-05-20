extends Node
##
## KingdomTheme — palette tokens + helpers translated from
## docs/user_ressources/bio-identity-system.jsx.
##
## Provides per-kingdom color sets (plantae/fungi/animals/hybrid) and per-
## resource colors. Consumers query KingdomTheme.* to apply consistent visual
## identity across HUD, panels, evolution tree, etc.
##
## Fonts:
## - Default theme font is Press Start 2P (chunky pixel, headers + body).
## - SMALL_FONT is Tiny5 (compact pixel, for Latin names, tooltips, tight rows).
##   Apply via:  control.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
##   Apply size: control.add_theme_font_size_override("font_size", 8)
##

const SMALL_FONT: FontFile = preload("res://assets/ui/fonts/Tiny5-Regular.ttf")
const SMALL_FONT_SIZE: int = 8

const KINGDOMS: Dictionary[StringName, Dictionary] = {
	&"plantae": {
		"bg":           Color8(0x14, 0x10, 0x0a),
		"surface":      Color8(0x1e, 0x28, 0x18),
		"surface_mid":  Color8(0x24, 0x2e, 0x1c),
		"border":       Color8(0x3a, 0x4a, 0x2a),
		"border_hi":    Color8(0x4a, 0x5a, 0x38),
		"border_lo":    Color8(0x1a, 0x2a, 0x12),
		"accent":       Color8(0x5a, 0x9a, 0x3a),
		"accent_light": Color8(0x7e, 0xba, 0x5a),
		"accent_bright":Color8(0xa8, 0xe0, 0x78),
		"accent_dim":   Color8(0x3a, 0x6a, 0x2a),
		"text":         Color8(0x8a, 0xaa, 0x5a),
		"text_dim":     Color8(0x4a, 0x6a, 0x2a),
		"text_bright":  Color8(0xb8, 0xd8, 0x7a),
		"glow":         Color8(0x4a, 0x8a, 0x3a)
	},
	&"fungi": {
		"bg":           Color8(0x0e, 0x0a, 0x14),
		"surface":      Color8(0x16, 0x12, 0x1e),
		"surface_mid":  Color8(0x1c, 0x18, 0x26),
		"border":       Color8(0x3a, 0x2a, 0x44),
		"border_hi":    Color8(0x4a, 0x3a, 0x54),
		"border_lo":    Color8(0x1a, 0x12, 0x28),
		"accent":       Color8(0x7a, 0x4a, 0x9a),
		"accent_light": Color8(0xaa, 0x7a, 0xca),
		"accent_bright":Color8(0xd0, 0xa8, 0xf0),
		"accent_dim":   Color8(0x4a, 0x2a, 0x5a),
		"text":         Color8(0x9a, 0x7a, 0xba),
		"text_dim":     Color8(0x5a, 0x4a, 0x6a),
		"text_bright":  Color8(0xc8, 0xa8, 0xe8),
		"glow":         Color8(0x6a, 0x3a, 0x8a)
	},
	&"animals": {
		"bg":           Color8(0x12, 0x10, 0x0a),
		"surface":      Color8(0x2a, 0x22, 0x18),
		"surface_mid":  Color8(0x30, 0x28, 0x18),
		"border":       Color8(0x4a, 0x3a, 0x22),
		"border_hi":    Color8(0x5a, 0x4a, 0x2a),
		"border_lo":    Color8(0x2a, 0x1e, 0x12),
		"accent":       Color8(0xba, 0x8a, 0x4a),
		"accent_light": Color8(0xda, 0xa8, 0x5a),
		"accent_bright":Color8(0xf0, 0xc8, 0x78),
		"accent_dim":   Color8(0x6a, 0x4a, 0x2a),
		"text":         Color8(0xc8, 0xa8, 0x58),
		"text_dim":     Color8(0x7a, 0x6a, 0x3a),
		"text_bright":  Color8(0xf0, 0xd8, 0x80),
		"glow":         Color8(0x8a, 0x6a, 0x2a)
	},
	&"hybrid": {
		"bg":           Color8(0x0a, 0x10, 0x10),
		"surface":      Color8(0x12, 0x1e, 0x1e),
		"surface_mid":  Color8(0x18, 0x24, 0x24),
		"border":       Color8(0x1a, 0x3a, 0x34),
		"border_hi":    Color8(0x2a, 0x4a, 0x44),
		"border_lo":    Color8(0x0a, 0x1a, 0x18),
		"accent":       Color8(0x3a, 0x8a, 0x7a),
		"accent_light": Color8(0x5a, 0xaa, 0x98),
		"accent_bright":Color8(0x88, 0xd8, 0xc8),
		"accent_dim":   Color8(0x1a, 0x4a, 0x4a),
		"text":         Color8(0x5a, 0x9a, 0x8a),
		"text_dim":     Color8(0x3a, 0x6a, 0x5a),
		"text_bright":  Color8(0x88, 0xc8, 0xb8),
		"glow":         Color8(0x3a, 0x7a, 0x6a)
	}
}

const RESOURCES: Dictionary[StringName, Color] = {
	&"biomass":           Color8(0x7e, 0xba, 0x5a),
	&"nutrients":         Color8(0xd8, 0xb8, 0x58),
	&"sunlight":          Color8(0x88, 0xcc, 0xee),
	&"decay":             Color8(0xaa, 0x7a, 0xca),
	&"spores":            Color8(0x7a, 0x9a, 0xba),
	&"protein":           Color8(0xda, 0xa8, 0x5a),
	&"lifeforce":         Color8(0xc8, 0x5a, 0x5a),
	&"pollination":       Color8(0xb8, 0xc8, 0x4a),
	&"cellulose":         Color8(0x8a, 0xaa, 0x6a),
	&"chitin":            Color8(0x9a, 0x8a, 0x6a),
	&"phosphate":         Color8(0x6a, 0x9a, 0xba),
	&"blood_cohesion":    Color8(0xc8, 0x5a, 0x5a),
	&"gray_matter":       Color8(0xb0, 0xb0, 0xc8),
	&"mycelial_stability":Color8(0xaa, 0x7a, 0xca),
	&"ep":                Color8(0xe8, 0xd0, 0x70)
}


func resource_color(resource_id: StringName) -> Color:
	return RESOURCES.get(resource_id, Color(0.85, 0.85, 0.85))


func kingdom_palette(kingdom_id: StringName) -> Dictionary:
	return KINGDOMS.get(kingdom_id, KINGDOMS[&"plantae"])


# Build a chunky panel stylebox in a kingdom's voice — 2px borders, light-on-top
# / dark-on-bottom for pixel-aesthetic depth.
func panel_stylebox(kingdom_id: StringName) -> StyleBoxFlat:
	var p: Dictionary = kingdom_palette(kingdom_id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = p["surface"]
	sb.border_color = p["border"]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func current_kingdom_id() -> StringName:
	# Read the denormalized run-state field set by PrestigeSystem.start_run.
	var k: StringName = StringName(GameState.run_save.get("starting_species_kingdom_id", ""))
	if k != &"":
		return k
	return StringName(GameState.current_kingdom_id)
