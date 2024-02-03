extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


@rpc("any_peer","call_remote","unreliable")
func sync_pos_rpc(pos : Vector2):
	pass


@rpc("any_peer","reliable")
func spawn_object_rpc(object_path : String,pos : Vector2,rotation : float,object_id : int):
	pass
