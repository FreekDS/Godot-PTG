extends Spatial

const MAX_THREADS = 3

const chunk_size = 64
const chunk_amount = 16

var noise

var chunks = {}
var unready_chunks = {}
var thread


func _ready():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	
	# what terrain should look like
	noise.octaves = 6
	noise.period = 80
	
	thread = Thread.new()
	
	
func add_chunk(x, z):
	var key = str(x) + ',' + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	if not thread.is_active():
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1


func load_chunk(array):
	var thread = array[0]
	var x = array[1]
	var z = array[2]
	
	# Multiply by chunk size to get the actual location of the noise
	var chunk = Chunk.new(noise, x * chunk_size, z * chunk_size, chunk_size)
	chunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)
	
	call_deferred("load_done", chunk, thread)


func load_done(chunk, thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + ',' + str(chunk.z / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()
	
func get_chunk(x, z):
	var key = str(x) + ',' + str(z)
	if chunks.has(key):
		return chunks[key]
	else:
		return null
		
func _process(_delta):
	update_chunks()
	cleanup_chunks()
	reset_chunks()

func update_chunks():
	
	var player_translation = $Player.translation
	var p_x = int(player_translation.x / chunk_size)
	var p_z = int(player_translation.z / chunk_size)
	
	for x in range(p_x - chunk_amount / 2.0, p_x + chunk_amount / 2.0):
		for z in range(p_z - chunk_amount / 2.0, p_z + chunk_amount / 2.0):
			add_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				chunk.should_remove = false
	pass
	
func cleanup_chunks():
	for key in chunks:
		if chunks[key].should_remove:
			chunks[key].queue_free()
			chunks.erase(key)

func reset_chunks():
	for key in chunks:
		var chunk = chunks[key]
		chunk.should_remove = true