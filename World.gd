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

master func action_check(sender_id, phase):
	if sender_id == 0:
		sender_id = 1
	if sender_id != get_current_player():
		print("not your turn")
		return false
	if current_phase != phase:
		print("incorrect phase")
		return false
	return true


master func roll_dice():
	var sender_id = get_tree().get_rpc_sender_id()
	if not action_check(sender_id, Turn_Phase.ROLL):
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
	if not action_check(sender_id, Turn_Phase.PLACEMENT):
		return
	$Board.request_place_building(x, y, color)


func _on_Board_place_building(x, y, color):
	print("place building")
	if get_tree().is_network_server():
		request_place_building(x, y, color)
	else:
		rpc_id(1, "request_place_building", x, y, color)


remotesync func update_turn_phase(phase):
	current_phase = phase


func my_turn():
	return get_current_player() == get_tree().get_network_unique_id()


func _on_Board_end_turn():
	#if current_phase == Turn_Phase.END and my_turn(): 
	if get_tree().is_network_server():
		end_turn()
	else:
		rpc_id(1, "end_turn")


master func end_turn():
	var sender_id = get_tree().get_rpc_sender_id()
	if not action_check(sender_id, Turn_Phase.END):
		return
	rpc("next_player")
	rpc("update_turn_phase", Turn_Phase.ROLL)
	$Board.rpc("begin_turn")

	
remotesync func next_player():
	var player_index = current_player + 1
	if player_index > player_turn_order.size() - 1:
		player_index = 0
	set_current_player(player_index)


master func _on_Board_end_placement_phase():	
	rpc("update_turn_phase",Turn_Phase.END)


master func _on_Board_stock_val_change(stock_delta, stock_color):
	var cur_stock_val = $StocksContainer.stocks[stock_color]
	if stock_delta == 0:
		pay_isolated_bonus()
		if cur_stock_val == 0:
			stock_delta = 1
	#Prevent stock from going 1-3
	if cur_stock_val == 1 and stock_delta == 2:
		stock_delta = 1
	$StocksContainer.stock_value_change(stock_delta, stock_color)
	for p_id in player_turn_order:
		var player = get_player_node(p_id)
		player.stock_value_change(stock_delta, stock_color)
	if stock_delta > 0:
		pay_stock_bonus(stock_color)
	
	
#Current Player paid bonus when stock reaches new value equal to new value	
master func pay_stock_bonus(stock_color):
	var cur_stock_val = $StocksContainer.stocks[stock_color]
	var cur_player = get_current_player()
	var bonus = cur_stock_val * gamestate.SINGLE_STOCK_VAL
	print("stock price bonus" + str(bonus))
	get_player_node(cur_player).rpc("update_money", bonus)			


master func pay_isolated_bonus():
	var cur_player = get_current_player()
	var bonus = gamestate.SINGLE_STOCK_VAL
	print("isolated bonus" + str(bonus))
	get_player_node(cur_player).rpc("update_money", bonus)		
