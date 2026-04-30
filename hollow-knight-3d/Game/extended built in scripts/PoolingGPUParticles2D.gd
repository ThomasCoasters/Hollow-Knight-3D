## a base class made to make the pooling easier for GPUParticles2D
class_name PoolingGPUParticles2D
extends GPUParticles2D


## connect the finished signal to the return
func _ready() -> void:
	#connect it
	finished.connect(func ():
		# add a timer that makes sure that the animation is REEAAAAAAAAAALY finished
		await get_tree().create_timer(lifetime).timeout
		# call the return object
		get_parent().return_object.bind(self)
	)


## is the disabling code for the particle
func _on_pool_disable() -> void:
	# stop emitting the particle
	emitting = false

## is the enabling code for the particle
func _on_pool_enable() -> void:
	pass

## runs when the pool gets the particle
func _on_pool_get() -> void:
	# start emitting the particle
	emitting = true

## runs when the particle is returned to the pool
func _on_pool_return() -> void:
	pass
