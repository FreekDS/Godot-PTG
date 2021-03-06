extends Spatial

# Noise related variables
export var world_seed = 0
export(int, 50, 500) var chunk_size = 100
export(int, 1, 9) var octaves = 5
export var period = 100
export var lacunarity = 7
export var persistence = 0.2
export(float, 1, 200, 0.5) var height_multiplier = 5.0


# Infinite terrain variables
export(int, 2, 16) var view_distance = 16
export(int, 2, 16) var collision_distance = 4
export(PackedScene) var player_object


# Materials
export var mat : Material = preload("res://materials/terrain.material")


# Regenerate options
export(bool) var show_noise = false setget update_img


# Class variables
var noise_generator: Noise.NoiseGenerator

var chunk_dict: Dictionary = {}
var unready_chunks: Dictionary = {}
var collider_dict: Dictionary = {}
var unready_colliders: Dictionary = {}


var threads: Array = []
var max_threads = 8

var physics_threads: Array = []
var max_physics_threads = 8

var update_movement_threshold = 10
var old_position


""""

Spawn one chunk
param x: x coordinate of chunk
param z: z coordinate of chunk

"""
func spawn_chunk(x=0, z=0):
	var key = Vector2(x, z)
	
	# Chunk is present, or is loading
	if chunk_dict.has(key) or unready_chunks.has(key):
		return

	if threads.size() < max_threads:
		
		var thread = Thread.new()
		threads.append(thread)
		unready_chunks[key] = 1

		var err = thread.start(self, "load_chunk", [thread, x, z])
		if err != OK:
			print("Failure in creating thread!")


func load_chunk(args):
	var thread: Thread = args[0]
	var x : float = args[1]
	var z : float = args[2]
	
	# Generate chunk and display it
	var chunk = Chunk.new(noise_generator, x * chunk_size, z * chunk_size, chunk_size, height_multiplier)
	chunk.set_terrain_material(mat)
	chunk.generate_chunk()
	chunk.display_chunk(get_world().scenario)
	
	call_deferred("finalize_load", chunk, thread)


func finalize_load(chunk : Chunk, thread : Thread):
	var key = Vector2(chunk.x/chunk_size, chunk.z / chunk_size)
	
	if thread != null and thread.is_active():
		thread.wait_to_finish()

	var index = threads.find(thread)
	if index != -1:
		threads.remove(index)
	
	# Apparently creating the collider must happen in the main thread
	# Else the game crashes without any notice
	chunk.create_collider(get_world().space)
	chunk_dict[key] = chunk
	
# warning-ignore:return_value_discarded
	unready_chunks.erase(key)

# Simple image display
func update_img(_value):
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
	if player_object == null:
		player_object = $Player
	noise_generator = Noise.BasicGenerator.new(
		world_seed, octaves, period, lacunarity, persistence
	)
	old_position = player_object.transform.origin
	update_chunks()


func get_chunk(x, z):
	var key = Vector2(x, z)
	if chunk_dict.has(key):
		return chunk_dict[key]
	else:
		return null


func _process(_delta):
	
	var pos = player_object.transform.origin
	
	var count = chunk_dict.size()
	
	if pos.distance_squared_to(old_position) >= update_movement_threshold or count < view_distance * view_distance:
		update_chunks()	
		cleanup_chunks()
		reset_chunks()
		old_position = pos


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
# warning-ignore:return_value_discarded
			chunk_dict.erase(key)


func reset_chunks():
	for key in chunk_dict:
		var chunk = chunk_dict[key]
		chunk.should_remove = true

