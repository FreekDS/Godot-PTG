extends Spatial

# Noise related variables
export var world_seed = 0
export var chunk_size = 100
export var octaves = 5
export var period = 100
export var lacunarity = 7
export var persistence = 0.2
export(float, 1, 200, 0.5) var height_multiplier = 5.0


# Infinite terrain variables
export(int, 2, 16) var view_distance = 16
export(PackedScene) var player_object


# Materials
export var mat : Material = preload("res://materials/terrain.material")


# Regenerate options
export(bool) var show_noise = false setget update_img
export(bool) var regenerate_chunk = false setget regen_chunk


# Class variables
var chunks : Array
var noise_generator: Noise.NoiseGenerator
var chunk_dict: Dictionary = {}
var unready_chunks: Dictionary = {}
var generation_thread: Thread


func regen_chunk(value):
	regenerate_chunk = false
	if noise_generator != null:
		update_noise_params()
		for child in $Chunks.get_children():
			child.queue_free()
		spawn_chunk()


# Spawn one chunk
func spawn_chunk(x=0, z=0):
	var key = Vector2(x, z)
	
	# Chunk is present, or is loading
	if chunk_dict.has(key) or unready_chunks.has(key):
		return

	if chunks == null:
		return
		
	if not generation_thread.is_active():
		unready_chunks[key] = 1
		#load_chunk([generation_thread, x, z])
		var _f = generation_thread.start(self, "load_chunk", [generation_thread, x, z])


func load_chunk(args):
	var thread: Thread = args[0]
	var x : float = args[1]
	var z : float = args[2]
	
	var chunk = Chunk.new(noise_generator, x * chunk_size, z * chunk_size, chunk_size, height_multiplier)
	chunk.generate_chunk()
	chunk.set_terrain_material(mat)
	chunk.display_chunk(get_world().scenario)
	
	#finalize_load(chunk, thread)

	call_deferred("finalize_load", chunk, thread)


func finalize_load(chunk : Chunk, thread : Thread):
	chunks.append(chunk)
	var key = Vector2(chunk.x/chunk_size, chunk.z / chunk_size)
	chunk_dict[key] = chunk
	unready_chunks.erase(key)
	
	if thread.is_active():
		thread.wait_to_finish()


# Simple image display
func update_img(value):
	if noise_generator == null:
		return
	var tex = ImageTexture.new()
	update_noise_params()
	tex.create_from_image(noise_generator.get_image(chunk_size))
	$TextureRect.set_texture(tex)


func update_noise_params():
	noise_generator.set_lacunarity(lacunarity)
	noise_generator.set_octaves(octaves)
	noise_generator.set_persistence(persistence)
	noise_generator.set_period(period)
	noise_generator.set_seed(world_seed)


func _ready():
	self.chunks = []
	if player_object == null:
		player_object = $Player
	generation_thread = Thread.new()
	noise_generator = Noise.BasicGenerator.new(
		world_seed, octaves, period, lacunarity, persistence
	)


func get_chunk(x, z):
	var key = Vector2(x, z)
	if chunk_dict.has(key):
		return chunk_dict[key]
	else:
		return null


func _process(_delta):
	update_chunks()
	cleanup_chunks()
	reset_chunks()


func update_chunks():
	
	var player_translation = player_object.translation
	var p_x = int(player_translation.x / chunk_size)
	var p_z = int(player_translation.z / chunk_size)
	
	for x in range(p_x - view_distance * 0.5, p_x + view_distance * 0.5):
		for z in range(p_z - view_distance * 0.5, p_z + view_distance * 0.5):
			spawn_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				chunk.should_remove = false

func cleanup_chunks():
	var chunk : Chunk
	for key in chunk_dict:
		chunk = chunk_dict[key]
		if chunk.should_remove:
			chunk.clear()
			chunk_dict.erase(key)


func reset_chunks():
	for key in chunk_dict:
		var chunk = chunk_dict[key]
		chunk.should_remove = true


func spiral(X, Y):
	var x = 0
	var y = 0
	var dx = 0
	var dy = -1
	
	var m = max(X, Y) 
	
	for i in range(m * m):
		if (-X/2 < x and x <= X/2) and (-Y/2 < y and y <= Y/2):
			print(x, y)
		if x == y or (x < 0 and x == -y) or (x>0 and x == 1-y):
			var temp = dx
			dx = -dy
			dy = temp
		x += dx
		y += dy
