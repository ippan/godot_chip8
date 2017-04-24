extends Control

var Chip8 = preload("chip8.gd")
onready var file_dialog = get_node("file_dialog")

var chip8
var pause = false

func _ready():
	set_fixed_process(true)

func load_rom():
	file_dialog.show_modal(true)
	file_dialog.invalidate()

func on_load_rom(path):
	chip8 = Chip8.new()
	chip8.load_rom(path)
	get_node("view").set_texture(chip8.get_graphics().get_texture())
	pause = false

# fixed process set to 60fps
func _fixed_process(delta):
	if chip8 != null and !pause:
		chip8.update_timer()
		
		# run at 480hz
		for i in range(8):
			chip8.step()

func on_pause():
	pause = !pause
