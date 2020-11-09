extends VBoxContainer

signal trade_stock()

# Stock counts in id:number.
var stocks = {
	gamestate.Stock_Color.YELLOW: 0,
	gamestate.Stock_Color.RED: 0,
	gamestate.Stock_Color.BLUE: 0,
	gamestate.Stock_Color.GREEN: 0,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


master func stock_value_change(stock_delta, stock_color):
	rpc("set_stock", stock_delta, stock_color)
	

remotesync func set_stock(stock_delta, stock_color):
	stocks[stock_color] += stock_delta
	$RedStock.text = "$" + str(stocks[gamestate.Stock_Color.RED] * gamestate.SINGLE_STOCK_VAL)
	$BlueStock.text = "$" + str(stocks[gamestate.Stock_Color.BLUE] * gamestate.SINGLE_STOCK_VAL)
	$GreenStock.text = "$" + str(stocks[gamestate.Stock_Color.GREEN] * gamestate.SINGLE_STOCK_VAL)
	$YellowStock.text = "$" + str(stocks[gamestate.Stock_Color.YELLOW] * gamestate.SINGLE_STOCK_VAL)	

func trade_stock(stock_color, amount):
	var price = stocks[stock_color]
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
