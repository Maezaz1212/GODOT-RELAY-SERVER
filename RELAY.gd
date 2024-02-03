extends Node2D

### ALL CODE PERTAINING TO RELAY CONNECTION
var PLAYER_DICT = {}
var ROOMS = {}
var CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

# Called when the node enters the scene tree for the first time.
func _ready():
	var relay_peer = ENetMultiplayerPeer.new()
	var error = relay_peer.create_server(25566)
	if error:
		return(error)
	relay_peer.is_server_relay_supported()
	multiplayer.multiplayer_peer = relay_peer
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(multiplayer.multiplayer_peer.get_connection_status())
	pass

@rpc("any_peer","call_remote","reliable")
func _resgister_player():
	var new_player_id = multiplayer.get_remote_sender_id()
	PLAYER_DICT[new_player_id] = {
		"player_name":"EMPTY",
		"room_code":"EMPTY",
		"is_host":"false",
		"multiplayer_id":0
	}


func create_room_code():
	var id = ""
	for n in 5:
		var random_number =  randi_range(0,CHARS.length() -1)
		var random_char = CHARS[random_number]
		id+=random_char
	if ROOMS.has(id):
		return create_room_code()
	
	return id

@rpc("any_peer","call_remote","reliable")
func host_rpc():
	var room_code = create_room_code()
	var sender_id = multiplayer.get_remote_sender_id()
	PLAYER_DICT[sender_id].room_code = room_code
	
	ROOMS[room_code] = {
		"room_code":room_code,
		"host_id":0,
		"players":{},
		"max_players":3,
		"game_started":false,
		"is_public":false
	}
	
	ROOMS[room_code].host_id = sender_id
	ROOMS[room_code].players[sender_id] = PLAYER_DICT[sender_id]
	host_success_rpc.rpc_id(sender_id,room_code,ROOMS[room_code])
	sync_room_data_all(room_code)
	
@rpc("authority","call_remote","reliable")
func host_success_rpc(room_code : String,room_info : Dictionary):
	pass
	
@rpc("any_peer","call_remote","reliable")
func join_rpc(room_code : String):
	var sender_id = multiplayer.get_remote_sender_id()
	if !ROOMS.has(room_code):
		join_fail_rpc.rpc_id(sender_id,room_code,"NO ROOM FOUND")
		return
	
	if ROOMS[room_code].max_players >= ROOMS[room_code].players.size():
		join_fail_rpc.rpc_id(sender_id,room_code,"ROOM IS FULL")
		return
	
	ROOMS[room_code].players[sender_id] = PLAYER_DICT[sender_id]
	join_success_rpc.rpc_id(sender_id,room_code)
	sync_room_data_all(room_code)
	

@rpc("authority","call_remote","reliable")
func join_success_rpc(room_code : String):
	pass

@rpc("authority","call_remote","reliable")
func join_fail_rpc(room_code : String, error_message : String):
	pass
	
func sync_room_data_all(room_code : String):
	for player_id in ROOMS[room_code].players:
		sync_room_data_rpc.rpc_id(player_id,ROOMS[room_code])
		
@rpc("authority","reliable")
func sync_room_data_rpc(room_data : Dictionary):
	pass
	
### END OF RELAY SERVER CONNECTION 

### EMPTY RPCs FOR HOST TO CLIENTS
@rpc("any_peer","call_local","reliable")
func change_scene_rpc(scene_path : String):
	pass
