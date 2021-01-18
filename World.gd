extends Control

var current_player = -1
enum Turn_Phase {ROLL, PLACEMENT, SELL, END, GAME_OVER}
var current_phase = Turn_Phase.ROLL
var player_turn_order = []
var players_in_debt = []
var eliminated_players = []
var rng = RandomNumberGenerator.new()
const MAX_BUYS = 5
var total_stock_buys = 0
var pre_roll_buys = 0
var stock_buys = {
	gamestate.Stock_Color.YELLOW: 0,
	gamestate.Stock_Color.RED: 0,
	gamestate.Stock_Color.BLUE: 0,
	gamestate.Stock_Color.GREEN: 0,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if Input.is_action_just_released("console"):
		if $Console.visible:
			$Console.hide();
		else:
			$Console.display();

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

master func action_check(sender_id, valid_ids, phases):
	if sender_id == 0:
		sender_id = 1
	if not valid_ids.has(sender_id):
		print("not your turn")
		return false
	if not phases.has(current_phase):
		print("incorrect phase")
		return false
	return true


master func roll_dice():
	var sender_id = get_tree().get_rpc_sender_id()
	if not action_check(sender_id, [get_current_player()], [Turn_Phase.ROLL]):
		return
	print("rolling dice")
	rng.randomize()
	var quadrant_roll = rng.randi_range(1, 6)
	if quadrant_roll == 6:
		quadrant_roll = 5
	var color_roll = rng.randi_range(1, 6)
	$Board.rpc("dice_rolled", quadrant_roll, color_roll)
	reset_buys()
	rpc("update_turn_phase", Turn_Phase.PLACEMENT)


func trade_stock(stock_color, stock_price, amount):
	print("trade_stock " + str(stock_color) + "" + str(amount))
	var p_id = get_tree().get_network_unique_id()
	if get_tree().is_network_server():
		verify_trade(1, stock_color, stock_price, amount)
	else:
		rpc_id(1, "verify_trade", p_id, stock_color, stock_price, amount)


master func verify_trade(p_id, stock_color, stock_price, amount):
	var str_pid = str(p_id)
	if current_phase == Turn_Phase.SELL:
		if not action_check(p_id, players_in_debt, [Turn_Phase.SELL]):
			print("only players in debt can sell")
			return
	elif not action_check(p_id, [get_current_player()], [Turn_Phase.ROLL, Turn_Phase.END]):
		print("make trades on your turn/right phase")
		return	
	var player = get_player_node(p_id)
	if player == null:
		print("error player not found in verify trade")
		return
	print("verify trade " + str_pid + str(stock_color) + str(amount))
	if amount == 0 or stock_price == 0:
		return
	print("total buys: " + str(total_stock_buys))
	print("prerollbuys: " + str(pre_roll_buys))
	var incr = calc_total_incr(stock_color, amount)
	print("incr: " + str(incr))
	if total_stock_buys + pre_roll_buys + incr > MAX_BUYS:
		print("max buys reached")
		return
	make_trade(p_id, stock_color, stock_price, amount)


#Calculate how much total_buys would increase with this stock_color and amount
master func calc_total_incr(stock_color, amount):
	var old_value = stock_buys[stock_color]
	if old_value > 0:
		return amount
	else:
		return old_value + amount


master func reset_buys():
	if current_phase == Turn_Phase.END:
		pre_roll_buys = 0
		total_stock_buys = 0
	else:
		pre_roll_buys = total_stock_buys
		total_stock_buys = 0

	$StocksContainer.rpc("set_buys", total_stock_buys + pre_roll_buys, MAX_BUYS)	
	stock_buys = {
		gamestate.Stock_Color.YELLOW: 0,
		gamestate.Stock_Color.RED: 0,
		gamestate.Stock_Color.BLUE: 0,
		gamestate.Stock_Color.GREEN: 0,
	}


master func update_total_buys(stock_color, amount):	
	var buys = 0
	stock_buys[stock_color] += amount
	for stock in stock_buys:
		if stock_buys[stock] > 0:
			buys += stock_buys[stock]
	total_stock_buys = buys
	$StocksContainer.rpc("set_buys", total_stock_buys + pre_roll_buys, MAX_BUYS)
	print("total stock buys: " + str(total_stock_buys))


master func make_trade(p_id, stock_color, stock_price, amount):
	var player = get_player_node(p_id)
	if amount > 0 and $StocksContainer.stocks_left[stock_color] >= amount:
		var money = player.money
		if money >= stock_price * amount:
			update_total_buys(stock_color, amount)			
			player.rpc("buy_stock", stock_color, stock_price, amount)
			add_event_text(player.player_name + " bought " + str(amount) + " " + str(gamestate.Stock_Color.keys()[stock_color]) + " stock")
			$StocksContainer.rpc("stock_trade", amount*-1, stock_color)
		#Check if all stocks have been purchased
		if $StocksContainer.all_stocks_gone():
			print("all stocks gone")
			game_over()
	elif amount < 0:
		var stocks_available = player.stocks[stock_color]
		if stocks_available >= amount * -1:
			update_total_buys(stock_color, amount)
			player.rpc("sell_stock",stock_color, stock_price, amount)
			add_event_text(player.player_name + " sold " + str(amount) + " " + str(gamestate.Stock_Color.keys()[stock_color]) + " stock")
			$StocksContainer.rpc("stock_trade", amount*-1, stock_color)
			if current_phase == Turn_Phase.SELL and player.money >= 0:
				var p_index = players_in_debt.find(p_id)
				players_in_debt.remove(p_index)
				if players_in_debt.size() == 0:
					rpc("update_turn_phase", Turn_Phase.END)


func get_player_node(id):
	return get_node("Players/" + str(id))

 
remote func request_place_building(x, y, color):
	print("request place building")
	var sender_id = get_tree().get_rpc_sender_id()
	if not action_check(sender_id, [get_current_player()], [Turn_Phase.PLACEMENT]):
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
	if not action_check(sender_id, [get_current_player()], [Turn_Phase.END]):
		return
	var cur_player = get_current_player()
	var player = get_player_node(cur_player)		
	add_event_text(player.player_name + " Ended Turn")		
	rpc("next_player")
	reset_buys()	
	rpc("update_turn_phase", Turn_Phase.ROLL)
	$Board.rpc("begin_turn")

	
remotesync func next_player():
	var player_index = current_player + 1
	if player_index > player_turn_order.size() - 1:
		player_index = 0
	set_current_player(player_index)
	if player_index in eliminated_players:
		next_player()	


master func _on_Board_end_placement_phase():
	if players_in_debt.size() > 0:
		rpc("update_turn_phase", Turn_Phase.SELL)
	else:
		rpc("update_turn_phase", Turn_Phase.END)


master func get_chain_val(size, color, remainder):
	print("chain destroy called " + str(size) + " remain " + str(remainder))
	var stock_val = $StocksContainer.stock_price[color]
	if size > 1:
		if remainder > 0 and stock_val == size * gamestate.SINGLE_STOCK_VAL:
			return size -1
		return size
	else:
		if remainder > 0:
			return 0
		return size


master func chain_destroyed(size, color, remainder):
	var chain_val = get_chain_val(size, color, remainder)
	print("chain val: " + str(chain_val))
	_on_Board_stock_val_change(chain_val * -1, color)


master func _on_Board_stock_val_change(stock_delta, stock_color):
	var cur_stock_val = $StocksContainer.stock_price[stock_color]
	if stock_delta == 0:
		pay_isolated_bonus()
		if cur_stock_val == 0:
			stock_delta = 1
	print("cur_stock_val: " + str(cur_stock_val) + " stock_delta " + str(stock_delta))
	#Prevent stock from going 1-3
	if cur_stock_val == 1 * gamestate.SINGLE_STOCK_VAL and stock_delta > 1:
		print("subtract 1 from stock delta")
		stock_delta -= 1
	$StocksContainer.stock_value_change(stock_delta, stock_color)	
	print("paying players")
	for p_id in player_turn_order:
		var player = get_player_node(p_id)
		if stock_delta > 0 or (stock_delta < 0 and p_id != get_current_player()):
			player.stock_value_change(stock_delta, stock_color)
			if player.money < 0:
				print("player is in debt")
				if is_player_broke(player):
					remove_player_from_game(p_id)
				else:
					players_in_debt.push_front(p_id)
	if stock_delta > 0:
		pay_stock_bonus(stock_color)
	if $StocksContainer.is_stock_maxed(stock_color):
		print("stock value maxed")
		game_over()

master func game_over():
	add_event_text("Game Over!!")
	rpc("update_turn_phase", Turn_Phase.GAME_OVER)
	calculate_totals()	

master func calculate_totals():
	var winner = null
	for p_id in player_turn_order:
		var player = get_player_node(p_id)
		var score = player.money
		for color in gamestate.Stock_Color:
			print(color)
			score += player.stocks[gamestate.Stock_Color[color]] * $StocksContainer.stock_price[gamestate.Stock_Color[color]]
		player.rpc("set_final_score", score)
		if winner == null:
			winner = player
		elif winner.final_score < score:
			winner = player
	$Board.rpc("game_over", winner.player_name)


master func remove_player_from_game(p_id):
	var player = get_player_node(p_id)
	eliminated_players.push_front(p_id)
	player.rpc("eliminated")
	if player_turn_order.size() - eliminated_players.size() <= 1:
		print("only one player left game over")
		game_over()


master func is_player_broke(player):
		var money = player.money
		for color in gamestate.Stock_Color:
			money += player.stocks[gamestate.Stock_Color[color]] * $StocksContainer.stock_price[gamestate.Stock_Color[color]]
		if money >= 0:
			return false
		return true
	
 
#Current Player paid bonus when stock reaches new value equal to new value	
master func pay_stock_bonus(stock_color):
	var cur_stock_val = $StocksContainer.stock_price[stock_color]
	var cur_player = get_current_player()
	var bonus = cur_stock_val
	print("stock price bonus" + str(bonus))
	var player = get_player_node(cur_player)
	player.rpc("update_money", bonus)
	add_event_text(player.player_name + " earned $" + str(bonus) + " stock bonus")		


master func pay_isolated_bonus():
	var cur_player = get_current_player()
	var bonus = gamestate.SINGLE_STOCK_VAL
	print("isolated bonus" + str(bonus))
	var player = get_player_node(cur_player)
	player.rpc("update_money", bonus)
	add_event_text(player.player_name + " earned $" + str(bonus) + " isolation bonus")

master func add_event_text(event):
	rpc("send_event_text", event)

remotesync func send_event_text(event):
	var cur_text = $Events/Text.text
	$Events/Text.text = str(event) + "\n" + cur_text


master func building_placed_add_event(color):
	var cur_player = get_current_player()
	var player = get_player_node(cur_player)
	add_event_text(player.player_name + " Placed " + gamestate.Stock_Color.keys()[color] + " building")


func _on_Console_command_entered(args):
	if args.empty():
		return
	if args[0] == "builder":
		$Board.set_unlimited_building()
