@icon("health_component.svg")
@tool

##component used to act as an health system
class_name health_component
extends component


## the max amount of heath the object can have
@export var max_health: int:
	set(value):
		#emit the signal for changing max health
		max_health_changed.emit(max_health, value)
		
		#change the max health value to the new value
		max_health = value
		
		
		#heal when that variable is true
		if heal_on_max_health_gain:
			health = max_health


## if the health wil go to max when the max health is changed
@export var heal_on_max_health_gain: bool = false




## the health the object currently has
var health: int:
	set(value):
		#do not play in the editor
		if Engine.is_editor_hint():
			return
		
		#make the new health never go above or below limits
		var new_health = clamp(value, 0, max_health)
		
		#if the new health is 0 emit the depleated signal
		if new_health == 0 && health > 0:
			health_depleated.emit()
		
		
		#emit the signal for changing health
		health_changed.emit(health, new_health)
		
		
		#emits the correct health gained or reduced signal
		if health < new_health:
			healed.emit(health, new_health)
		elif health > new_health:
			damaged.emit(health, new_health)
		
		
		#change the health value to the new value
		health = new_health

## an extra bonus multiplier to the damage 
@export var damage_mult: float = 1.0

## an extra bonus multiplier to the heal 
@export var heal_mult: float = 1.0


## called when the "health" var is changed
signal max_health_changed(new_max_health: int, old_max_health: int)

## called when the "health" var is changed
signal health_changed(new_health: int, old_health: int)

## called when the "health" var is higher than the previous
signal healed(new_health: int, old_health: int)

## called when the "health" var is lower than the previous
signal damaged(new_health: int, old_health: int)


## called when the "health" var is 0
signal health_depleated()



func _ready():
	if Engine.is_editor_hint():
		return
	
	#set the health up propperly
	health = max_health



## reduces the health by the specified amount.
## also applies damage bonuses
func damage(amount: int, extra_damage_mult: float = 1.0) -> void:
	#reduces the health
	health -= amount * damage_mult * extra_damage_mult


## increases the health by the specified amount.
## also applies healing bonuses
func heal(amount: int, extra_heal_mult: float = 1.0) -> void:
	#increases the health
	health += amount * heal_mult * extra_heal_mult



## returns the percentage the health is in comparisant to the max health.
## returns as a float of 0.0 to 100.0
func get_current_health_percentage() -> float:
	#returns the percentage of health left
	return (health / max_health) * 100


## returns true if the health is higher than 0 (alive). Else false.
func is_alive() -> bool:
	return health > 0


## instantly sets the health to 0
func kill():
	#sets hp to 0 (kill)
	health = 0

## returns the health to the specified amount of health.
## if negative the health will be max health
func revive(amount: int = -1):
	#if negative heal to max health
	if amount < 0:
		health = max_health
	
	#if not negative set the health to that amount
	else:
		#make the health not just instantly kill or go above max health
		health = clamp(amount, 1, max_health)
