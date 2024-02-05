extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@rpc("any_peer","call_remote","unreliable")	
func player_move_command(move_dir : Vector2):
	pass

@rpc("any_peer","call_remote","unreliable")	
func player_jump_command(jump_command : bool):
	pass

@rpc("any_peer","call_local","reliable")	
func player_attack_command():
	pass

@rpc("any_peer","call_remote","unreliable")
func sync_player_pos_rpc(pos : Vector2):
	pass


@rpc("any_peer","reliable")
func spawn_object_rpc(object_path : String,pos : Vector2,rotation : float,object_id : int):
	pass

@rpc("any_peer","call_local","reliable")
func change_scene_rpc(scene_path : String):
	pass
