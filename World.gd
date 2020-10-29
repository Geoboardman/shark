extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func trade_stock(stock_color, stock_price, amount):
	print("trade_stock " + str(stock_color) + "" + str(amount))
	var p_id = get_tree().get_network_unique_id()
	if get_tree().is_network_server():
		verify_trade(1, stock_color, stock_price, amount)
	else:
		rpc_id(1, "verify_trade", p_id, stock_color, stock_price, amount)

remote func verify_trade(p_id, stock_color, stock_price, amount):
	var str_pid = str(p_id)
	var player = get_node("Players/" + str_pid)
	if player == null:
		print("error player not found in verify trade")
		return
	print("verify trade " + str_pid + str(stock_color) + str(amount))
	if amount == 0:
		return
	elif amount > 0:
		var money = player.money
		if money >= stock_price * amount:
			player.buy_stock(stock_color, stock_price, amount)
	elif amount < 0:
		var stocks_available = player.stocks[stock_color]
		if stocks_available >= amount:
			player.sell_stock(stock_color, stock_price, amount)

