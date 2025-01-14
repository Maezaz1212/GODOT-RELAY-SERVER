extends Node

const ROOM_CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
@export var PLAYER_DICT = {}
@export var ROOMS = {}


### ALL CODE PERTAINING TO RELAY CONNECTION

## Supplementary functions
func create_room_code():
	var id = ""
	for n in 5:
		var random_number =  randi_range(0,ROOM_CODE_CHARS.length() -1)
		var random_char = ROOM_CODE_CHARS[random_number]
		id+=random_char
	if ROOMS.has(id):
		return create_room_code()
	
	return id
	

func _ready():
	
	var relay_peer = WebSocketMultiplayerPeer.new()
	var crypto = Crypto.new()
	var key = crypto.generate_rsa(4096)
	var cert = crypto.generate_self_signed_certificate(key, "CN=localhost,O=myorganisation,C=IT")
	var error = relay_peer.create_server(25566,"*",TLSOptions.server(key,cert))
	
	if error:
		return(error)
	multiplayer.multiplayer_peer = relay_peer
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	
## CREATES PLAYER ON JOIN
@rpc("any_peer","call_remote","reliable")
func _resgister_player(game_name):
	var new_player_id = multiplayer.get_remote_sender_id()
	PLAYER_DICT[new_player_id] = {
		"room_code":"EMPTY",
		"game_name":game_name,
		"is_host":false,
		"multiplayer_id":0
	}

func _on_player_disconnected(id):
	
	if !PLAYER_DICT.has(id):
		return

	var player_data = PLAYER_DICT[id]
	var room_code = player_data.room_code
	
	if player_data.is_host == true:
		ROOMS[room_code].players.erase(id)
		close_room(room_code,id)
	elif ROOMS.has(room_code):
		ROOMS[room_code].players.erase(id)
		remove_player(room_code,id)
	PLAYER_DICT.erase(id)

@rpc("any_peer","call_remote","reliable")
func leave_command():
	var sender_id = multiplayer.get_remote_sender_id()
	var player_room_id = PLAYER_DICT[sender_id].room_code
	if ROOMS.has(player_room_id):
		if ROOMS[player_room_id].host_id == sender_id:
			close_room(player_room_id,sender_id)
		else:
			remove_player(player_room_id,sender_id)

func close_room(room_code,sender_id):
	for player_id in ROOMS[room_code].players:
		room_closed.rpc_id(player_id)
	PLAYER_DICT[sender_id].is_host = false
	PLAYER_DICT[sender_id].room_code = "EMPTY"
	ROOMS.erase(room_code)
	
@rpc("any_peer","call_remote","reliable")
func remove_player_command(player_to_remove):
	var sender_id = multiplayer.get_remote_sender_id()
	var player_room_id = PLAYER_DICT[sender_id].room_code
	if ROOMS.has(player_room_id):
		if ROOMS[player_room_id].host_id == sender_id:
			remove_player(player_room_id,player_to_remove)

func remove_player(room_code,player_id_to_remove):
	for player_id in ROOMS[room_code].players:
		player_disconnect_room.rpc_id(player_id,player_id_to_remove)
	if(PLAYER_DICT.has(player_id_to_remove)):
		PLAYER_DICT[player_id_to_remove].room_code = "EMPTY"
		PLAYER_DICT[player_id_to_remove].is_host = false
	
	ROOMS[room_code].players.erase(player_id_to_remove)
	sync_room_data_all(room_code)

## HOSTING ROOM CODE
@rpc("any_peer","call_remote","reliable")
func host_rpc():
	var room_code = create_room_code()
	var sender_id = multiplayer.get_remote_sender_id()
	PLAYER_DICT[sender_id].room_code = room_code
	PLAYER_DICT[sender_id].is_host = true;
	ROOMS[room_code] = {
		"room_code":room_code,
		"game_name":PLAYER_DICT[sender_id].game_name,
		"host_id":sender_id,
		"players":{},
		"max_players":3,
		"game_started":false,
		"is_public":false
	}
	
	ROOMS[room_code].players[sender_id] = PLAYER_DICT[sender_id]
	host_success_rpc.rpc_id(sender_id,room_code,ROOMS[room_code])
	sync_room_data_all(room_code)
	
@rpc("authority","call_remote","reliable")
func host_success_rpc(room_code : String,room_info : Dictionary):
	pass

@rpc("authority","call_remote","reliable")
func host_fail_rpc(room_code : String, error_message : String):
	pass	


## JOINING ROOM CODE
@rpc("any_peer","call_remote","reliable")
func join_rpc(room_code : String):
	var sender_id = multiplayer.get_remote_sender_id()
	if !ROOMS.has(room_code):
		join_fail_rpc.rpc_id(sender_id,room_code,"NO ROOM FOUND")
		return
	
	if ROOMS[room_code].max_players <= ROOMS[room_code].players.size():
		join_fail_rpc.rpc_id(sender_id,room_code,"ROOM IS FULL")
		return
	
	if ROOMS[room_code].game_started:
		join_fail_rpc.rpc_id(sender_id,room_code,"GAME HAS STARTED")
		return
	
	if ROOMS[room_code].game_name != PLAYER_DICT[sender_id].game_name:
		join_fail_rpc.rpc_id(sender_id,room_code,"CODE NOT FOR THIS GAME")
		return
		
	PLAYER_DICT[sender_id].room_code = room_code
	ROOMS[room_code].players[sender_id] = PLAYER_DICT[sender_id]
	for player_id in ROOMS[room_code].players:
		join_success_rpc.rpc_id(player_id,ROOMS[room_code],sender_id)
	sync_room_data_all(room_code)
	

@rpc("authority","call_remote","reliable")
func join_success_rpc(room_info : Dictionary, player_id_joined : int):
	pass

@rpc("authority","call_remote","reliable")
func join_fail_rpc(room_code : String, error_message : String):
	pass

@rpc("authority","call_remote","reliable")
func player_disconnect_room(player_disconnecting_id):
	pass

@rpc("authority","call_remote","reliable")
func room_closed():
	pass
## Sync room info
func sync_room_data_all(room_code : String):
	for player_id in ROOMS[room_code].players:
		sync_room_data_rpc.rpc_id(player_id,ROOMS[room_code])
		
@rpc("authority","reliable")
func sync_room_data_rpc(room_data : Dictionary):
	pass
	
@rpc("any_peer","reliable")
func game_started_rpc(started : bool):
	var sender_id = multiplayer.get_remote_sender_id()
	var room_id  = PLAYER_DICT[sender_id].room_code
	ROOMS[room_id].game_started = started
	
### END OF RELAY SERVER CONNECTION 


