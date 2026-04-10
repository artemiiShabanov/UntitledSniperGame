class_name ArmyUpgrade
extends Resource
## A permanent army upgrade unlocked by completing its paired opportunity for the first time.

@export var id: String = ""
@export var name: String = ""
@export var effect_key: String = ""      ## System key for applying the effect
@export var effect_value: float = 0.0    ## Magnitude of the effect
@export var description: String = ""
@export var visual_description: String = ""  ## Flavor text for the War Room display
