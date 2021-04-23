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
export(int, 2, 16) var view_distance = 8
export(PackedScene) var player_object


# Materials
export var mat : Material = preload("res://materials/terrain.material")


# Regenerate options
export(bool) var show_noise = false setget update_img
export(bool) var regenerate_chunk = false setget regen_chunk


# Class variables
var chunks : Spatial
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
	var key = String(x) + ',' + String(z)
	
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
	
	var chunk = Chunk.new(noise_generator, chunk_size, x * chunk_size, z * chunk_size, height_multiplier)
	chunk.generate_chunk()
	chunk.set_terrain_material(mat)
	chunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)
		
	call_deferred("finalize_load", chunk, thread)


func finalize_load(chunk : Chunk, thread : Thread):
	chunks.add_child(chunk)
	var key = String(chunk.chunk_x / chunk_size) + ',' + String(chunk.chunk_z / chunk_size)
	chunk_dict[key] = chunk
	unready_chunks.erase(key)
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
	chunks = $Chunks
	if player_object == null:
		player_object = $Player
	generation_thread = Thread.new()
	noise_generator = Noise.BasicGenerator.new(
		world_seed, octaves, period, lacunarity, persistence
	)


func get_chunk(x, z):
	var key = str(x) + ',' + str(z)
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
			spawn_chunk(-x, -z)
			var chunk = get_chunk(-x, -z)
			if chunk != null:
				chunk.should_remove = false

func cleanup_chunks():
	for key in chunk_dict:
		if chunk_dict[key].should_remove:
			chunk_dict[key].queue_free()
			chunk_dict.erase(key)

func reset_chunks():
	for key in chunk_dict:
		var chunk = chunk_dict[key]
		chunk.should_remove = true
