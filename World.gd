extends Control

var current_player = -1
enum Turn_Phase {ROLL, PLACEMENT, END}
var current_phase = Turn_Phase.ROLL
var player_turn_order = []
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_current_player():
	return player_turn_order[current_player]


func set_current_player(index):
	#remove highlight from current player
	var p
	if current_player >= 0:
		p = get_player_node(player_turn_order[current_player])
		p.set_current_player(false)
	p = get_player_node(player_turn_order[index])
	p.set_current_player(true)
	current_player = index


func get_turn_array():
	return player_turn_order


func request_roll_dice():
	print("request rolling dice")
	if get_tree().is_network_server():
		roll_dice()
	else:
		rpc_id(1, "roll_dice")


master func roll_dice():
	var sender_id = get_tree().get_rpc_sender_id()
	if sender_id == 0:
		sender_id = 1
	if sender_id != get_current_player():
		print("not your turn")
		return
	if current_phase != Turn_Phase.ROLL:
		print("not roll phase")
		return
	print("rolling dice")
	rng.randomize()
	var quadrant_roll = rng.randi_range(1, 6)
	if quadrant_roll == 6:
		quadrant_roll = 5
	var color_roll = rng.randi_range(1, 6)
	$Board.rpc("dice_rolled", quadrant_roll, color_roll)
	current_phase = Turn_Phase.PLACEMENT # TODO do we need to sync this among all clients? For client side checking/updates?
	

func trade_stock(stock_color, stock_price, amount):
	print("trade_stock " + str(stock_color) + "" + str(amount))
	var p_id = get_tree().get_network_unique_id()
	if get_tree().is_network_server():
		verify_trade(1, stock_color, stock_price, amount)
	else:
		rpc_id(1, "verify_trade", p_id, stock_color, stock_price, amount)


remote func verify_trade(p_id, stock_color, stock_price, amount):
	var str_pid = str(p_id)
	var player = get_player_node(p_id)
	if player == null:
		print("error player not found in verify trade")
		return
	print("verify trade " + str_pid + str(stock_color) + str(amount))
	if amount == 0 or stock_price == 0:
		return
	elif amount > 0:
		var money = player.money
		if money >= stock_price * amount:
			player.rpc("buy_stock", stock_color, stock_price, amount)
	elif amount < 0:
		var stocks_available = player.stocks[stock_color]
		if stocks_available >= amount * -1:
			player.rpc("sell_stock",stock_color, stock_price, amount)


func get_player_node(id):
	return get_node("Players/" + str(id))


remote func request_place_building(x, y, color):
	print("request place building")
	var sender_id = get_tree().get_rpc_sender_id()
	if sender_id == 0:
		sender_id = 1
	if sender_id != get_current_player():
		print("not your turn")
		return
	if current_phase != Turn_Phase.PLACEMENT:
		print("its not placement phase")
		return
	$Board.request_place_building(x, y, color)


func _on_Board_place_building(x, y, color):
	print("place building")
	if get_tree().is_network_server():
		request_place_building(x, y, color)
	else:
		rpc_id(1, "request_place_building")
