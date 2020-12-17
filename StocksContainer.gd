extends VBoxContainer

signal trade_stock()

var buys_left = 0
const STOCK_START_COUNT = 22
const MAX_STOCK_VALUE = 15000
# Stock counts in id:number.
var stock_price = {
	gamestate.Stock_Color.YELLOW: 14000,
	gamestate.Stock_Color.RED: 14000,
	gamestate.Stock_Color.BLUE: 14000,
	gamestate.Stock_Color.GREEN: 14000,
}
var stocks_left = {
	gamestate.Stock_Color.YELLOW: STOCK_START_COUNT,
	gamestate.Stock_Color.RED: STOCK_START_COUNT,
	gamestate.Stock_Color.BLUE: STOCK_START_COUNT,
	gamestate.Stock_Color.GREEN: STOCK_START_COUNT,
}



# Called when the node enters the scene tree for the first time.
func _ready():
	pass


master func is_stock_maxed(stock_color):
	if stock_price[stock_color] >= MAX_STOCK_VALUE:
		return true
	return false

master func stock_value_change(stock_delta, stock_color):
	rpc("set_stock", stock_delta, stock_color)


remotesync func set_buys(buys, max_buys):
	buys_left = buys
	$Buys.text = "Buys " + str(buys_left) + "/" + str(max_buys)


remotesync func set_stock(stock_delta, stock_color):
	print("stock changed: " + str(stock_delta))
	stock_price[stock_color] += stock_delta * gamestate.SINGLE_STOCK_VAL
	$RedStock.text = "$" + str(stock_price[gamestate.Stock_Color.RED])
	$BlueStock.text = "$" + str(stock_price[gamestate.Stock_Color.BLUE])
	$GreenStock.text = "$" + str(stock_price[gamestate.Stock_Color.GREEN])
	$YellowStock.text = "$" + str(stock_price[gamestate.Stock_Color.YELLOW])	


remotesync func stock_trade(amount, stock_color):
	stocks_left[stock_color] += amount
	var new_text = "(" + str(stocks_left[stock_color]) + ")"
	if stock_color == gamestate.Stock_Color.RED:
		$HBoxContainer/Red.text = new_text
	elif stock_color == gamestate.Stock_Color.BLUE:
		$HBoxContainer2/Blue.text = new_text
	elif stock_color == gamestate.Stock_Color.GREEN:
		$HBoxContainer4/Green.text = new_text
	elif stock_color == gamestate.Stock_Color.YELLOW:
		$HBoxContainer3/Yellow.text = new_text		

func trade_stock(stock_color, amount):
	var price = stock_price[stock_color]
	emit_signal("trade_stock", stock_color, price, amount)

func _red_buy():
	trade_stock(gamestate.Stock_Color.RED, 1)

func _red_sell():
	trade_stock(gamestate.Stock_Color.RED, -1)

func _blue_buy():
	trade_stock(gamestate.Stock_Color.BLUE, 1)

func _blue_sell():
	trade_stock(gamestate.Stock_Color.BLUE, -1)
	
func _green_buy():
	trade_stock(gamestate.Stock_Color.GREEN, 1)

func _green_sell():
	trade_stock(gamestate.Stock_Color.GREEN, -1)
	
func _yellow_buy():
	trade_stock(gamestate.Stock_Color.YELLOW, 1)

func _yellow_sell():
	trade_stock(gamestate.Stock_Color.YELLOW, -1)
