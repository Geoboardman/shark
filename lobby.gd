extends Control

onready var blueStockImg = preload("res://Art/blue.png")
onready var redStockImg = preload("res://Art/red.png")
onready var greenStockImg = preload("res://Art/green.png")
onready var yellowStockImg = preload("res://Art/yellow.png")

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	gamestate.connect("start_button_disabled", self, "start_button_disabled")
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]


func start_button_disabled(disable):
	$Players/Start.disabled = disable

func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name = $Connect/Name.text
	gamestate.host_game(player_name)
	refresh_lobby()


func _on_join_pressed():
	print("join button pressed")
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	gamestate.join_game(ip, player_name)


func _on_connection_success():
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func get_stock_icon(color):
	if(color == gamestate.Stock_Color.RED):
		return redStockImg
	elif(color == gamestate.Stock_Color.BLUE):
		return blueStockImg
	elif(color == gamestate.Stock_Color.YELLOW):
		return yellowStockImg
	elif(color == gamestate.Stock_Color.GREEN):
		return greenStockImg
	else:
		return null						

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	for p in players:
		var icon = get_stock_icon(p.stock)
		$Players/List.add_item(p.name, icon)		


func _on_start_pressed():
	gamestate.begin_game()

func _on_RedStockBox_button_up():
	gamestate.rpc("choose_stock", gamestate.Stock_Color.RED)


func _on_BlueStockBox_button_up():
	gamestate.rpc("choose_stock", gamestate.Stock_Color.BLUE)


func _on_GreenStockBox_button_up():
	gamestate.rpc("choose_stock", gamestate.Stock_Color.GREEN)


func _on_YellowStockBox_button_up():
	gamestate.rpc("choose_stock", gamestate.Stock_Color.YELLOW)
