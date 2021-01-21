extends Node

# Default game port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10589
const SINGLE_STOCK_VAL = 1000
# Max number of players.
const MAX_PEERS = 12
enum Stock_Color {RED, YELLOW, BLUE, GREEN}
var peer = null
var rng = RandomNumberGenerator.new()

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal start_button_disabled()


#func _process(delta):
	#if peer:
		#if peer.is_listening(): # is_listening is true when the server is active and listening
			#peer.poll();
		#if (peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED ||
		#peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
			#peer.poll();

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	print("player connected idz: " + str(id))
	var my_id = get_tree().get_network_unique_id()
	if not players.has(my_id):
		print("adding self")
		players[my_id] = {
			"name": players[0]["name"],
			"stock": players[0]["stock"],
			}
		players.erase(0)
	rpc_id(id, "register_player", players[my_id]["name"], players[my_id]["stock"])


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id]["name"] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

func change_start_stock(stock_color):
	print("change start stock")
	rpc("choose_stock", stock_color)

master func start_button_disabled():
	for p in players:
		if players[p].stock == null:
			return true
	return false

#Change player starting stock
remotesync func choose_stock(stock_color):
	var id = get_tree().get_rpc_sender_id()
	print("choose start stock: " + str(id))
	players[id].stock = stock_color
	emit_signal("player_list_changed")
	if get_tree().is_network_server():
		var disable = start_button_disabled()
		emit_signal("start_button_disabled", disable)

# Lobby management functions.

remote func register_player(new_player_name, stock):
	print("register player: " + new_player_name)
	var id = get_tree().get_rpc_sender_id()
	print(id)
	players[id] = {
		"name": new_player_name,
		"stock": stock,
		}
	emit_signal("player_list_changed")


func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

func RandomlyPickFirstPlayer():
	rng.randomize()
	return rng.randi_range(0, players.size()-1)

remotesync func pre_start_game(first):
	# Change scene.
	var world = load("res://World.tscn").instance()
	print("first player: " + str(first))
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()
	for p in players:
		world.player_turn_order.push_back(p)
	world.player_turn_order.sort()
	var player_scene = load("res://Player.tscn")
	for p in world.player_turn_order:
		var player = player_scene.instance()
		player.set_name(str(p)) # Use unique ID as node name.
		player.player_name = players[p].name
		player.set_stock(players[p].stock, 1)
		player.set_network_master(1) #set unique id as master.
		player.connect("add_event_text", world, "add_event_text")
		world.get_node("Players").add_child(player)
	world.set_current_player(first)
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 1:
		post_start_game()
	else:
		ready_to_start(1)


remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name):
	#peer = NetworkedMultiplayerENet.new()
	#peer.create_server(DEFAULT_PORT, MAX_PEERS)
	peer = WebSocketServer.new()
	peer.listen(DEFAULT_PORT, PoolStringArray(), true)		
	get_tree().set_network_peer(peer)
	players[1] = {
		"name": new_player_name,
		"stock": null,
		}	


func join_game(ip, new_player_name):
	#peer = NetworkedMultiplayerENet.new()
	#peer.create_client(ip, DEFAULT_PORT)
	peer = WebSocketClient.new()
	peer.connect_to_url("ws://" + str(ip) + ":" + str(DEFAULT_PORT), PoolStringArray(), true)
	get_tree().set_network_peer(peer)
	var id = get_tree().get_network_unique_id()
	print("join game: " + str(id))
	players[id] = {
		"name": new_player_name,
		"stock": null,
		}		


func get_player_list():
	return players.values()


func begin_game():
	assert(get_tree().is_network_server())
	var first = RandomlyPickFirstPlayer()
	rpc("pre_start_game", first)


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
