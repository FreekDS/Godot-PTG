extends Spatial


export(Resource) var generator = preload("res://TerrainGenerators/TestTerrain.tres") setget set_gen
export(Material) var terrainMaterial = preload("res://terrain.material") setget set_mat


var TheChunk: NativeChunk
var ready = false


func set_mat(mat):
	if ready:
		TheChunk.set_material(mat)
	terrainMaterial = mat
		

func set_gen(gen):
	if ready:
		print("TODO: create set generator in GDNative")
	generator = gen


func _ready():
	var chunk : NativeChunk = NativeChunk.new()
	chunk.initialize(0, 0, generator, 0, 1)
	chunk.set_material(terrainMaterial)
	add_child(chunk)
	TheChunk = chunk
	rebuild_chunk()
	ready = true


func rebuild_chunk():
	TheChunk.generate()
	

func switch_LOD(level):
	TheChunk.switch_lod(level)
	
	
func _process(delta):
	if ready:
		TheChunk.rotate_y(1 * delta)

	

