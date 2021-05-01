class_name Chunk2

const border_size = 1

var size : float
var x : float
var z : float
var height_multiplier : float	# TODO move to Noise generator?
var noise : Noise.NoiseGenerator
var should_remove : bool = true

var terrain_material : Material
var mesh : Mesh

# Visualization
var visual_instance = null

func _init(noise_generator, x, z, size, height_multiplier):
	self.noise = noise_generator
	self.x = x
	self.z = z
	self.size = size
	self.height_multiplier = height_multiplier
	self.mesh = null


func get_mesh() -> Mesh:
	assert(mesh != null, 'Mesh should be generated first')
	return mesh


# TODO: borders are being generated so there are overlapping
# vertices. fix this later
# in short chunk_size is replaced by chunk_size + 1
# TODO: fix normals on borders to make transition seamless
func generate_chunk():
	
	if self.mesh != null:
		return
	
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var triangles = PoolIntArray()

	verts.resize((self.size+1) * (self.size+1))
	uvs.resize((self.size+1) * (self.size+1))
	normals.resize((self.size+1) * (self.size+1))
	triangles.resize((self.size) * (self.size) * 6)
	
	
	var i = 0
	var triangle_i = 0
	
	var topleft_x : float = (self.size) / 2.0
	var topleft_z : float = -topleft_x
	
	for z in range(self.size+1):
		for x in range(self.size+1):
			verts[i] = Vector3(topleft_x + x, noise.get_value(self.x + x, self.z + z) * self.height_multiplier, topleft_z + z)
			uvs[i] = Vector2(x / float(self.size+1), z / float(self.size+1))
			
			if(x < self.size and z < self.size):
				
				# First triangle of face
				triangles[triangle_i] = i
				triangles[triangle_i + 1] = i + self.size + 2
				triangles[triangle_i + 2] = i + self.size + 1
				
				# Second triangle of face
				triangles[triangle_i + 3] = i + self.size + 2
				triangles[triangle_i + 4] = i
				triangles[triangle_i + 5] = i + 1
				
				triangle_i += 6
			
			i += 1
		
	for ti in range(triangles.size() / 3):
		
		var triangle_index = ti * 3
		
		var index_a = triangles[triangle_index]
		var index_b = triangles[triangle_index + 1]
		var index_c = triangles[triangle_index + 2]
		
		var a: Vector3 = verts[index_a]
		var b: Vector3 = verts[index_b]
		var c: Vector3 = verts[index_c]
		
		
		var AB = b - a
		var AC = c - a
		
		
		var normal_value = AC.cross(AB).normalized()
		
		
		normals[index_a] += normal_value
		normals[index_b] += normal_value
		normals[index_c] += normal_value
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = triangles
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, terrain_material)
	
	self.mesh = mesh


func clear():
	if self.visual_instance != null:
		VisualServer.free_rid(self.visual_instance)
	if self.mesh == null:
		return
	#self.mesh.free()


func get_world_location() -> Vector3:
	return Vector3(self.x, 0, self.z)
	
	
func display_chunk(world_scenario: RID):
	assert(self.mesh != null, "Generate chunk first!")
	if self.visual_instance == null:
		self.visual_instance = VisualServer.instance_create2(get_mesh().get_rid(), world_scenario)
	else:
		VisualServer.instance_set_base(self.visual_instance, get_mesh().get_rid())
	if self.terrain_material != null:
		VisualServer.instance_set_surface_material(self.visual_instance, 0, terrain_material.get_rid())
	
	var transform = Transform(Basis(), get_world_location())
	VisualServer.instance_set_transform(self.visual_instance, transform)


func set_visible(value: bool):
	assert(self.visual_instance != null, "Mesh is not visualized by display()")
	VisualServer.instance_set_visible(self.visual_instance, value)


func set_terrain_material(mat: Material):
	self.terrain_material = mat
