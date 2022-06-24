extends Spatial

"""VARIABLES"""

const THREADED = true
const CHUNK_SCALE = 1

# Generation
#export var world_seed = 22
#export(int, 1, 9) var octaves = 5
#export var period = 100
#export var lacunarity = 7
#export var persistence = 0.2
#export(Curve) var heighContribution
#
#var noise = OpenSimplexNoise.new()

var t_Gen = preload("res://TerrainGenerators/TestTerrain.tres")
var terrain_material = preload("res://terrain.material")

var SCALED_SIZE
var CHUNK_SIZE


# Infinite terrain
export(int, 6, 32, 2) var view_distance = 14
export(NodePath) onready var TrackNode = get_node(TrackNode) as Spatial

# CHUNK_RANGE: CHUNK_LEVEL
export(Dictionary) var LOD_RANGES = {
	0: 0,
	2: 1,
	4: 2,
	6: 3,
	8: 4,
	10: 5
}

var chunks: Dictionary = {}
var loading_chunks: Dictionary = {}

var lastChunkPos = Vector2.ZERO


# Threading
const MAX_THREADS = 20
var threads = []

# Other variables
var initialized = false
signal spawn_area_created


"""GODOT OVERRIDDEN FUNCTIONS"""

func _ready():
#	noise.seed = world_seed
#	noise.octaves = octaves
#	noise.period = period
#	noise.lacunarity = lacunarity
#	noise.persistence = persistence
	var c = NativeChunk.new()
	c.initialize(0, 0, null, 0, CHUNK_SCALE)
	SCALED_SIZE = c.get_scaled_size()
	CHUNK_SIZE = c.get_size()
	c.queue_free()

	create_chunk(0,0)
#	create_chunk(0,1)
#	create_chunk(1,0)
#	create_chunk(1,1)


func _process(delta):
#	return
	manage_chunks(delta)
	
	if not initialized:
		if len(chunks) >= view_distance * view_distance:
			emit_signal("spawn_area_created")
			print("Spawn area created")
			initialized = true
	

"""FUNCTIONS"""

func manage_chunks(_delta = 0):
	
	var track_translation = TrackNode.translation

	var scaled_x = int(track_translation.x / (SCALED_SIZE / 2))
	var scaled_z = int(track_translation.z / (SCALED_SIZE / 2))
	
	var chunk_x = int(track_translation.x / CHUNK_SIZE)
	var chunk_z = int(track_translation.z / CHUNK_SIZE)
	
	chunk_x = scaled_x
	chunk_z = scaled_z
	
	var chunkPos = Vector2(scaled_x, scaled_z)
	
	if chunkPos == self.lastChunkPos and len(chunks) >= view_distance * view_distance:
		return
	
	self.lastChunkPos = chunkPos
	generate_new_chunks(chunk_x, chunk_z)
#	remove_obsolete_chunks()
#	reset_chunks()


func generate_new_chunks(chunk_x, chunk_z):
	# Generate new chunks in the required radius around the track object
	# @param chunk_x: chunk pos x of the tracked object
	# @param chunk_z: chunk pos z of the tracked object
	
	var half_dist = self.view_distance * .5
	
	for dx in range(chunk_x - half_dist, chunk_x + half_dist):
		for dy in range(chunk_z - half_dist, chunk_z + half_dist):
			create_chunk(dx, dy)

func remove_obsolete_chunks():
	# Remove chunks that should be removed
	
	for key in chunks:
		var chunk: Chunk = chunks[key]
		if chunk.remove_me:
			chunks.erase(key)
			chunk.queue_free()

func reset_chunks():
	# Reset the state of all chunks to be removed
	# Loop in generate_new_chunks makes sure required chunks stay.
	
	for key in chunks:
		var chunk = chunks[key]
		chunk.remove_me = true


func create_chunk(x=0, z=0):
	# Start a thread if there is one available to create a chunk
	# Lives in main thread
	# @param x: x position of chunk
	# @param z: z position of chunk
	
	
	var key = Vector2(x, z)
	if chunks.has(key) or loading_chunks.has(key):
		return # no need to generate chunk that exists/is already loading
	
	
	if not THREADED:
		load_chunk([null, x, z])
		return
	
	if threads.size() < MAX_THREADS:
		var new_thread = Thread.new()
		threads.append(new_thread)
		
		loading_chunks[key] = true
		
		var err = new_thread.start(self, "load_chunk", [new_thread, x, z])
		if err != OK:
			printerr("Could not instantiate terrain gen thread")

func load_chunk(args):
	# Actually generate the chunk
	# Lives in separate thread
	# @param args: list of arguments:
	#	0: thread
	#	1: x
	#	2: z
	
	var thread = args[0]
	var x = args[1]
	var z = args[2]
	
	var chunk_pos = Vector2(x, z)
	var chunk_distance = chunk_pos.distance_to(lastChunkPos)
	var lod = 0
		
	var chunk = NativeChunk.new()
	chunk.initialize(x, z, t_Gen, 5, CHUNK_SCALE)
	chunk.set_material(terrain_material)
	chunk.generate()
	
	call_deferred("finialize_chunk", chunk, Vector2(x, z), thread)

func finialize_chunk(chunk: NativeChunk, chunk_key: Vector2, thread: Thread):
	# Cleanup thread and add chunk to the scene tree
	if thread != null and thread.is_active():
		thread.wait_to_finish()
	
	var i = threads.find(thread)
	if i != -1:
		threads.remove(i)
	
	loading_chunks.erase(chunk_key)
	chunks[chunk_key] = chunk

	add_child(chunk)
	
func _exit_tree():
	for t in threads:
		t.wait_to_finish()

