extends Panel

const MAX_BUILDINGS = 20
const TILE = preload("res://Tile.tscn")
const tile_width = 32;
export var ROWS = 12;
export var COLUMNS = 12;
var tileArray = []
var quadrant_roll
var color_roll
var buildings_on_board = {
	gamestate.Stock_Color.YELLOW: 0,
	gamestate.Stock_Color.RED: 0,
	gamestate.Stock_Color.BLUE: 0,
	gamestate.Stock_Color.GREEN: 0,
}

var buildings_left = {
	gamestate.Stock_Color.YELLOW: MAX_BUILDINGS,
	gamestate.Stock_Color.RED: MAX_BUILDINGS,
	gamestate.Stock_Color.BLUE: MAX_BUILDINGS,
	gamestate.Stock_Color.GREEN: MAX_BUILDINGS,
}

signal roll_dice()
signal place_building()
signal end_turn()
signal end_placement_phase()
signal stock_val_change()
signal chain_destroyed()
signal game_over()

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_board_tiles()
	center_on_screen()
	position_roll_btn()


func center_on_screen():
	var x_offset = COLUMNS * tile_width * -1 / 2
	rect_position = rect_position + Vector2(x_offset, 0)


func position_roll_btn():
	var roll_box = get_node("RollVBox")
	var pos = roll_box.get_position()
	roll_box.set_position(Vector2(pos.x + ROWS * tile_width / 2 - 55, pos.y + COLUMNS * tile_width + 25))


func get_adjacent_tiles(x, y):
	var adjacent = []
	if x > 1: #left
		adjacent.append(tileArray[x-1][y])
	if x < COLUMNS-1: #right
		adjacent.append(tileArray[x+1][y])
	if y < ROWS-1: #down
		adjacent.append(tileArray[x][y+1])
	if y > 0: #up
		adjacent.append(tileArray[x][y-1])
	return adjacent


master func request_place_building(x, y, color):
	var enemy_chains = []
	print("x: " + str(x) + " y: " + str(y))
	var tile = tileArray[x][y]
	if tile.quadrant != quadrant_roll:
		print("quadrant wrong " + str(tile.quadrant) + " " + str("quadrant roll: ") + str(quadrant_roll))
		return
	if tile.color != null:
		print("already has building")
		return
	var adjacent = get_adjacent_tiles(x, y)
	for adj in adjacent:
		if adj.color != null and adj.color != color:
			print("adjacent has building")
			var enemy = get_building_chain(adj.x, adj.y, adj.color)
			enemy_chains.push_back(enemy)
	if enemy_chains.size() > 0:
		#Hacky code, updating color to get the theoretical chain if building was placed already
		tileArray[x][y].color = color
		var my_chain = get_building_chain(x, y, color)
		tileArray[x][y].color = null
		for enemy_chain in enemy_chains:
			if enemy_chain.size() >= my_chain.size():
				print("can't place next to enemy chain")
				return
	#SUCCESS!
	var stock_incr = get_stock_increase(x, y, color)
	#Payout players
	emit_signal("stock_val_change", stock_incr, color)
	#Place building
	rpc("building_placed", x, y, color)
	#Destroy enemy chains
	if enemy_chains.size() > 0:
		for chain in enemy_chains:
			var chain_color = chain[0].color
			destroy_chain(chain)
			emit_signal("chain_destroyed", chain.size(), chain_color, buildings_on_board[chain_color])
	#Update buildings left
	buildings_left[color] -= 1
	if buildings_left[color] < 1:
		emit_signal("game_over")
		return
	#Move to next phase
	emit_signal("end_placement_phase")
	rpc("end_phase_ui_update")


master func destroy_chain(chain):
	var color = chain[0].color
	buildings_on_board[color] -= chain.size()
	if buildings_on_board[color] < 0:
		buildings_on_board[color] = 0
	for tile in chain:
		tile.rpc("destroy")

master func get_stock_increase(x, y, color):
	var solo_tiles = 0
	var base_increase = 0
	var adj_tiles = get_adjacent_tiles(x, y)
	for adj in adj_tiles:
		if adj.color == color:
			base_increase = 1
			var solo_adj_tiles = get_adjacent_tiles(adj.x, adj.y)
			var is_solo = true
			for solo in solo_adj_tiles:
				if solo.color != null:
					is_solo = false
			if is_solo:
				solo_tiles += 1
	print('stock increase: ' + str(base_increase + solo_tiles))
	return base_increase + solo_tiles


remotesync func end_phase_ui_update():
	$RollVBox/Roll.hide()
	$RollVBox/StockChoices.hide()
	$RollVBox/Dice.hide()
	$RollVBox/EndTurn.show()


func get_building_chain(x, y, color):
	var seen = []
	var adj_tiles
	var to_process = [tileArray[x][y]]
	while to_process.size() > 0:
		var next_tile = to_process.pop_front()
		seen.push_back(next_tile)
		adj_tiles = get_adjacent_tiles(next_tile.x, next_tile.y)
		for adj in adj_tiles:
			if (not seen.has(adj)) and adj.color == color:
				to_process.push_back(adj)
	return seen


remotesync func building_placed(x, y, color):
	print("building placed: " + str(color))
	tileArray[x][y].set_color(color)
	buildings_on_board[color] += 1
	buildings_left[color] -= 1


func tile_clicked(x, y):
	if color_roll != null:
		emit_signal("place_building", x, y, color_roll)


func draw_board_tiles():
	for i in range(ROWS):
		tileArray.append([])
		for j in range(COLUMNS):
			var corner = false
			var quadrant = 0
			if j < COLUMNS/2:
				if i < ROWS/2:
					quadrant = 1
				else:
					quadrant = 2
			else:
				if i < ROWS/2:
					quadrant = 3
				else:
					quadrant = 4
			if j >= 3 && j < 9 && i >= 3 && i < 9:
				if (i == 3 && j == 3) || (i == 3 && j == 8) || (i == 8 && j == 3) || (i == 8 && j == 8):
					corner = true
				if corner == false:
					quadrant = 5
			var tile_instance = TILE.instance()
			tile_instance.init(quadrant)
			tile_instance.set_position(Vector2(i*tile_width, j*tile_width))
			tile_instance.x = i
			tile_instance.y = j
			$Tiles_Container.add_child(tile_instance)
			tileArray[i].append(tile_instance)
			tile_instance.connect("on_tile_clicked", self, "tile_clicked")


func _on_Roll_button_up():
	emit_signal("roll_dice")


func get_color_from_num(color_num):
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num == 1:
		return gamestate.Stock_Color.RED
	if color_num == 2:
		return gamestate.Stock_Color.YELLOW
	if color_num == 3:
		return gamestate.Stock_Color.GREEN				
	if color_num == 4:
		return gamestate.Stock_Color.BLUE		


remotesync func dice_rolled(quadrant, color_num):
	$RollVBox/DiceRoll.play()
	$RollVBox/StockChoices.hide()	
	$RollVBox/Roll.hide()
	quadrant_roll = quadrant
	color_roll = get_color_from_num(color_num)
	var frame = 0
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num <= 4:
		frame = quadrant_roll + color_num * 6 - 1
	else:
		frame = quadrant_roll - 1
		$RollVBox/StockChoices.show()	
	$RollVBox/Dice.frame = frame
	

func set_dice_image(quadrant, color_num):
	var frame = 0
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num <= 4:
		frame = quadrant + color_num * 6 - 1
	else:
		frame = quadrant_roll - 1
	$RollVBox/Dice.frame = frame


func _on_StockChoices_stock_picked(color):
	var color_num = 0
	if quadrant_roll == 0:
		return
	if color == gamestate.Stock_Color.RED:
		color_num = 1
	elif color == gamestate.Stock_Color.YELLOW:
		color_num = 2		
	elif color == gamestate.Stock_Color.GREEN:
		color_num = 3		
	elif color == gamestate.Stock_Color.BLUE:
		color_num = 4
	set_dice_image(quadrant_roll, color_num)
	color_roll = color				

remotesync func begin_turn():
	$RollVBox/Roll.show()
	$RollVBox/StockChoices.hide()
	$RollVBox/Dice.show()
	$RollVBox/EndTurn.hide()

func _on_EndTurn_button_up():
	emit_signal("end_turn")

remotesync func game_over(player_name):
	$RollVBox/Winner.text = str(player_name) + " Wins!!!"
	$RollVBox/Winner.show()
	$RollVBox/Roll.show()
	$RollVBox/StockChoices.hide()
	$RollVBox/Dice.hide()
	$RollVBox/EndTurn.hide()
