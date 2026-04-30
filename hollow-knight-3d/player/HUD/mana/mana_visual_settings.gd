@tool
class_name ManaVisualSettings
extends Resource

## amount of mana for when this should start
@export_range(0, 99, 1) var min_mana_amount: int = 0
## amount of mana for when this should end.
## ends when reaching this number (so it's exclusive).
## 100 is max
@export_range(0, 100, 1) var max_mana_amount: int = 0
## the color it will become when the percentage is hit.
## NOTE: do not use color AND texture color will override texture
@export var color: Color = Color(0, 0, 0, 0)
## the texture it will become when the percentage is hit.
## NOTE: do not use color AND texture color will override texture
@export var texture: Texture2D

## if the lighting should be dissabled
@export var pulsing_lighting: bool = false
