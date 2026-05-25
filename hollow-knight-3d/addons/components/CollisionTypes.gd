## settings for the type of collision for the collision component stuff
class_name CollisionTypes
extends RefCounted

## enum with specified bits that turn 1 or 0 when this one is selected
enum Type {
	PLAYER_BODY   = 1 << 0,
	PLAYER_ATTACK = 1 << 1,
	ENEMY_BODY    = 1 << 2,
	ENEMY_ATTACK  = 1 << 3,
	ENVIRONMENT   = 1 << 4
}


## string that makes the inspector dropdowns looking nicer
const FLAGS_STRING: String = "Player Body,Player Attack,Enemy Body,Enemy Attack,Environment"
