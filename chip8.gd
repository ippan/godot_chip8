
var pc = 0x200
var reg_v = RawArray()
var reg_i = 0
var delay_timer = 0
var sound_timer = 0

var stack = []

var memory = RawArray()

var graphics
var input

# font data
const character_sprites = [
	0xF0, 0x90, 0x90, 0x90, 0xF0,
	0x20, 0x60, 0x20, 0x20, 0x70,
	0xF0, 0x10, 0xF0, 0x80, 0xF0,
	0xF0, 0x10, 0xF0, 0x10, 0xF0,
	0x90, 0x90, 0xF0, 0x10, 0x10,
	0xF0, 0x80, 0xF0, 0x10, 0xF0,
	0xF0, 0x80, 0xF0, 0x90, 0xF0,
	0xF0, 0x10, 0x20, 0x40, 0x40,
	0xF0, 0x90, 0xF0, 0x90, 0xF0,
	0xF0, 0x90, 0xF0, 0x10, 0xF0,
	0xF0, 0x90, 0xF0, 0x90, 0x90,
	0xE0, 0x90, 0xE0, 0x90, 0xE0,
	0xF0, 0x80, 0x80, 0x80, 0xF0,
	0xE0, 0x90, 0x90, 0x90, 0xE0,
	0xF0, 0x80, 0xF0, 0x80, 0xF0,
	0xF0, 0x80, 0xF0, 0x80, 0x80
]

# a graphics class
class Graphics:
	const BUFFER_WIDTH = 64
	const BUFFER_HEIGHT = 32
	const BLACK = Color(0, 0, 0)
	const WHITE = Color(1, 1, 1)
	# use a image to store frame buffer
	var frame_buffer
	var texture
	
	func _init():
		frame_buffer = Image(BUFFER_WIDTH, BUFFER_HEIGHT, false, Image.FORMAT_RGB)
		texture = ImageTexture.new()
		texture.create_from_image(frame_buffer, 0)
		clear()

	func clear():
		for y in range(BUFFER_HEIGHT):
			for x in range(BUFFER_WIDTH):
				frame_buffer.put_pixel(x, y, BLACK)
		refresh()

	func set_pixel(x, y):
		var pixel = frame_buffer.get_pixel(x, y)
		
		if pixel == WHITE:
			frame_buffer.put_pixel(x, y, BLACK)
			return 1
		
		frame_buffer.put_pixel(x, y, WHITE)
		return 0
		
	func refresh():
		texture.set_data(frame_buffer)

	func draw_sprite(x, y, address, height, memory):
		var collision = 0
		
		for line in range(height):
			var pixels = memory[address + line]
			
			for bit in range(8):
				if (pixels >> (7 - bit)) & 1 == 1:
					if set_pixel(x + bit, y + line) == 1:
						collision = 1
		return collision

	func get_texture():
		return texture

class DefaultInput:
	const keys = [ KEY_X, KEY_1, KEY_2, KEY_3, KEY_Q, KEY_W, KEY_E, KEY_A, KEY_S, KEY_D, KEY_Z, KEY_C, KEY_4, KEY_R, KEY_F, KEY_V ]
	
	var key_states = []
	
	func _init():
		key_states.resize(0x10)
	
	func update():
		for i in range(keys.size()):
			if Input.is_key_pressed(keys[i]) == true:
				key_states[i] = 1
			else:
				key_states[i] = 0
	
	func key(code):
		return key_states[code]
	
	func any():
		for i in range(keys.size()):
			if key_states[i] == 1:
				return i
		
		return -1

func _init():
	reg_v.resize(16)
	memory.resize(4096)
	
	for i in range(character_sprites.size()):
		memory[i] = character_sprites[i]
	
	graphics = Graphics.new()
	input = DefaultInput.new()

func get_graphics():
	return graphics

func load_rom(path):
	var file = File.new()
	file.open(path, file.READ)
	var buffer = file.get_buffer(file.get_len())
	file.close()
	
	for i in range(buffer.size()):
		memory[0x200 + i] = buffer[i]

func step():
	var instruction = (memory[pc] << 8) | memory[pc + 1]
	pc += 2
	execute_instruction(instruction)

func update_timer():
	input.update()
	
	if delay_timer > 0:
		delay_timer -= 1
		
	if sound_timer > 0:
		sound_timer -= 1
		# TODO : play sound
		
func execute_instruction(instruction):
	var op = instruction & 0xF000
	
	var x = (instruction & 0x0F00) >> 8
	var y = (instruction & 0x00F0) >> 4
	var kk = instruction & 0x00FF
	var nnn = instruction & 0x0FFF
	var n = instruction & 0x000F
	
	if op == 0x0000:
		if instruction == 0x00E0:
			graphics.clear()
		elif instruction == 0x00EE:
			pc = stack.pop_back()
		
	elif op == 0x1000:
		pc = nnn
		
	elif op == 0x2000:
		stack.push_back(pc)
		pc = nnn
		
	elif op == 0x3000:
		if reg_v[x] == kk:
			pc += 2

	elif op == 0x4000:
		if reg_v[x] != kk:
			pc += 2

	elif op == 0x5000:
		if reg_v[x] == reg_v[y]:
			pc += 2
		
	elif op == 0x6000:
		reg_v[x] = kk
			
	elif op == 0x7000:
		reg_v[x] += kk
		
	elif op == 0x8000:
		if n == 0x00:
			reg_v[x] = reg_v[y]
		if n == 0x01:
			reg_v[x] |= reg_v[y]
			reg_v[0x0F] = 0
		elif n == 0x02:
			reg_v[x] &= reg_v[y]
			reg_v[0x0F] = 0
		elif n == 0x03:
			reg_v[x] ^= reg_v[y]
			reg_v[0x0F] = 0
		elif n == 0x04:
			var sum = reg_v[x] + reg_v[y]
			reg_v[x] = sum & 0xFF
			reg_v[0x0F] = sum >> 8
		elif n == 0x05:
			if reg_v[y] > reg_v[x]:
				reg_v[0x0F] = 0
			else:
				reg_v[0x0F] = 1
			
			reg_v[x] -= reg_v[y]
			
		elif n == 0x06:
			reg_v[0x0F] = reg_v[x] & 0x01
			reg_v[x] >>= 1
			
		elif n == 0x07:
			if reg_v[x] > reg_v[y]:
				reg_v[0x0F] = 0
			else:
				reg_v[0x0F] = 1
			
			reg_v[x] = reg_v[y] - reg_v[x]
			
		elif n == 0x0E:
			reg_v[0x0F] = reg_v[x] >> 7
			reg_v[x] <<= 1
		
	elif op == 0x9000:
		if reg_v[x] != reg_v[y]:
			pc += 2
		
	elif op == 0xA000:
		reg_i = nnn
		
	elif op == 0xB000:
		pc = nnn + reg_v[0x00]
		
	elif op == 0xC000:
		reg_v[x] = randi() & kk
		
	elif op == 0xD000:
		reg_v[0xF] = graphics.draw_sprite(reg_v[x], reg_v[y], reg_i, n, memory)
		graphics.refresh()
		
	elif op == 0xE000:
		if kk == 0x9E:
			if input.key(reg_v[x]) == 1:
				pc += 2
		elif kk == 0xA1:
			if input.key(reg_v[x]) == 0:
				pc += 2
		
	elif op == 0xF000:
		if kk == 0x07:
			reg_v[x] = delay_timer

		elif kk == 0x0A:
			var key = input.any()
			if key == -1:
				pc -= 2
			else:
				reg_v[x] = key
				
		elif kk == 0x15:
			delay_timer = reg_v[x]
			
		elif kk == 0x18:
			sound_timer = reg_v[x]
			
		elif kk == 0x1E:
			reg_i += reg_v[x]
			
		elif kk == 0x29:
			reg_i = reg_v[x] * 0x05

		elif kk == 0x33:
			memory[reg_i] = reg_v[x] / 100
			memory[reg_i + 1] = (reg_v[x] / 10) % 10
			memory[reg_i + 2] = reg_v[x] % 10
			
		elif kk == 0x55:
			for i in range(x + 1):
				memory[reg_i + i] = reg_v[i]
			
		elif kk == 0x65:
			for i in range(x + 1):
				reg_v[i] = memory[reg_i + i]
