extends Control

var Chip8 = preload("chip8.gd")
onready var file_dialog = get_node("file_dialog")
onready var registers_label = get_node("registers")

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

func dump_registers():
	var register_text = ""
	
	for i in range(4):
		for j in range(4):
			var index = i * 4 + j
			register_text += "V%X: %02X    " % [ index, chip8.reg_v[index] ]
			
		register_text += "\n"
	
	register_text += "\nI: %04X    DT: %02X    ST: %02X    PC: %04X" % [ chip8.reg_i, chip8.delay_timer, chip8.sound_timer, chip8.pc ]
	
	registers_label.set_text(register_text)

# fixed process set to 60fps
func _fixed_process(delta):
	if chip8 != null and !pause and chip8.loaded:
		chip8.update_timer()
		
		# run at 480hz
		for i in range(8):
			chip8.step()
			
		dump_registers()

func on_pause():
	pause = !pause
