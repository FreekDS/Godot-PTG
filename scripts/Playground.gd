extends Spatial


# Noise related variables
export var world_seed = 0
export var size = 100
export var octaves = 5
export var period = 100
export var lacunarity = 7
export var persistence = 0.2

# Terrain material
export var mat : Material = preload("res://materials/terrain.material")

# Regenerate options
export(bool) var show_noise = false setget update_img
export(bool) var regenerate_chunk = false setget regen_chunk

# Class variables
var chunks : Spatial
var noise_generator: Noise.NoiseGenerator

# Spawn one chunk

func regen_chunk(value):
	if noise_generator != null:
		noise_generator.set_lacunarity(lacunarity)
		noise_generator.set_octaves(octaves)
		noise_generator.set_persistence(persistence)
		noise_generator.set_period(period)
		noise_generator.set_seed(world_seed)
		for child in $Chunks.get_children():
			child.queue_free()
		spawn_chunk()
	


func spawn_chunk():
	if chunks != null:
		var chunk = Chunk.new(noise_generator, size, 0, 0)
		chunk.generate_chunk()
		chunk.material_terrain = mat
		chunks.add_child(chunk)

# Simple image display
func update_img(value):
	var tex = ImageTexture.new()
	tex.create_from_image(noise_generator.get_image(size))
	$TextureRect.set_texture(tex)


func _ready():
	chunks = $Chunks
	noise_generator = Noise.BasicGenerator.new(
		world_seed, octaves, period, lacunarity, persistence
	)
	spawn_chunk()


