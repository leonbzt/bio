extends Label
##
## Phase 15a: Floating income label that drifts up and fades out.
## Tuned 2026-05-20 for punch — was too subtle to feel rewarding.
##

const DRIFT_DISTANCE: float = 28.0     # was 18; rise farther
const DURATION: float = 1.8            # was 1.5; slightly longer life
const POP_SCALE: float = 1.45          # initial scale-up before settling
const POP_TIME: float = 0.12           # snap-pop in
const SETTLE_TIME: float = 0.18        # settle back to 1.0


const PIXEL_FONT: FontFile = preload("res://assets/ui/fonts/PressStart2P-Regular.ttf")


func _ready() -> void:
	# Press Start 2P at 16px (2× its 8px native grid → crisp pixel render).
	# Anti-aliasing disabled so glyphs stay sharp at any zoom.
	add_theme_font_override("font", PIXEL_FONT)
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", KingdomTheme.resource_color(&"biomass"))
	# Slight outline so the label reads on any biome.
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_theme_constant_override("outline_size", 3)
	z_index = 5
	pivot_offset = size * 0.5
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0

	# Snap-pop in: alpha + scale ramp up, then settle, then drift+fade.
	var tween := create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(POP_SCALE, POP_SCALE), POP_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, POP_TIME)
	tween.tween_property(self, "scale", Vector2.ONE, SETTLE_TIME)
	# Drift up + fade out together.
	tween.parallel().tween_property(self, "position:y", position.y - DRIFT_DISTANCE, DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION) \
		.set_delay(DURATION * 0.45)
	tween.tween_callback(queue_free)
