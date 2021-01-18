extends VBoxContainer

onready var input_box = get_node("input")
onready var output_box = get_node("output")

signal command_entered


# Called when the node enters the scene tree for the first time.
func _ready():
	input_box.grab_focus()
	
func output_text(text):
	output_box.text = str(output_box.text, "\n", text)

func _on_input_text_entered(new_text):
	input_box.clear()
	output_text(new_text)
	var args = new_text.split(" ")
	emit_signal("command_entered", args)
	
func display():
	show();
	input_box.clear()
	input_box.grab_focus()
	
