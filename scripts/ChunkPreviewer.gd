tool
extends Spatial

export var world_seed = 0 setget set_seed
export var chunk_size = 100 setget set_size
export var octaves = 5 setget set_octaves
export var period = 100 setget set_period
export var lacunarity = 7 setget set_lacunarity
export var persistence = 0.2 setget set_persistence
export(float, 1, 200, 0.5) var height_multiplier = 5.0 setget set_height

export(int) var x = 0 setget set_x
export(int) var z = 0 setget set_z

export(Material) var terrain = preload("res://materials/terrain.material") setget set_terrain


onready var chunk = $CUT
onready var display = $NoiseMap

var chunk_instance: Chunk = null

var ready = false

export var regen = false setget update



func set_seed(v):
	world_seed = v
	update()


func set_size(v):
	chunk_size = v
	update()


func set_octaves(v):
	octaves = v
	update()


func update(_value=null):
	regenerate_chunk()


func set_period(v):
	period = v
	update()


func set_lacunarity(v):
	lacunarity = v
	update()


func set_persistence(v):
	persistence = v
	update()


func set_height(v):
	height_multiplier = v
	update()


func set_x(v):
	x = v
	update()


func set_z(v):
	z = v
	update()


func set_terrain(v):
	terrain = v
	update()


func regenerate_chunk():
	if chunk == null:
		chunk = $CUT
		return
	var noise = Noise.BasicGenerator.new(world_seed, octaves, period, lacunarity, persistence)
	chunk_instance = Chunk.new(noise, x, z, chunk_size, height_multiplier)
	chunk_instance.generate_chunk()
	chunk.mesh = chunk_instance.get_mesh()
	chunk.mesh.surface_set_material(0, terrain)
	chunk.global_transform.origin = Vector3(-chunk_size,0,0)

