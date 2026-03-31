extends ColorRect
## Full-screen color rect that flashes on hit and fades out.

var _alpha: float = 0.0
const FADE_SPEED: float = 3.0


func flash() -> void:
	_alpha = 0.4
	color = Color(PaletteManager.get_color(PaletteManager.SLOT_DANGER), _alpha)


func _process(delta: float) -> void:
	if _alpha > 0.0:
		_alpha = maxf(_alpha - FADE_SPEED * delta, 0.0)
		color.a = _alpha
