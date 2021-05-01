extends Spatial

class_name Chunk

onready var mesh_instance : MeshInstance = $TerrainMesh
onready var water_mesh : MeshInstance = $WaterMesh
var noise : Noise.NoiseGenerator

var chunk_x : float
var chunk_z : float
var should_remove : bool
var height_multiplier : float

var chunk_generate_water = false setget set_generate_water
var chunk_size = 16 setget set_chunk_size

var chunk_water_offset = 0 setget set_water_offset

export var material_terrain : Material setget set_terrain_material
var material_water : Material


func update_height_multiplier(new_multiplier: float):
	self.height_multiplier = new_multiplier
	_trigger_update()

func update_size(new_size: int):
	self.chunk_size = new_size
	_trigger_update()

func update_noise(new_noise: Noise.NoiseGenerator):
	self.noise = new_noise

func _init(noise_generator: Noise.BasicGenerator, size, x, z, height_multiplier = 5.0):
	self.noise = noise_generator
	self.chunk_x = x
	self.chunk_z = z
	self.chunk_size = size
	self.height_multiplier = height_multiplier
	self.should_remove = true
	
	var terrain_mesh = MeshInstance.new()
	terrain_mesh.name = "TerrainMesh"
	add_child(terrain_mesh)
	
	var water_mesh = MeshInstance.new()
	water_mesh.name = "WaterMesh"
	add_child(water_mesh)
	
	self.mesh_instance = terrain_mesh
	self.water_mesh = water_mesh


func set_water_offset(value):
	chunk_water_offset = value
	if water_mesh.translation != null:
		water_mesh.translation = Vector3(water_mesh.translation.x, value, water_mesh.translation.z)
	else:
		water_mesh.translation = Vector3(chunk_x, value, chunk_z)

func set_terrain_material(new_material: Material):
	material_terrain = new_material
	if mesh_instance.mesh != null:
		mesh_instance.set_surface_material(0, new_material)

func _trigger_update():
	generate_chunk()
	if chunk_generate_water:
		generate_water()

func set_generate_water(value):
	chunk_generate_water = value
	if chunk_generate_water:
		generate_water()
	else:
		water_mesh.visible = false

func set_chunk_size(value):
	chunk_size = value
	#generate_chunk()
	if chunk_generate_water:
		pass
		#generate_water()


# TODO: borders are being generated so there are overlapping
# vertices. fix this later
# in short chunk_size is replaced by chunk_size + 1
# TODO: fix normals on borders to make transition seamless
func generate_chunk():
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var triangles = PoolIntArray()

	verts.resize((chunk_size+1) * (chunk_size+1))
	uvs.resize((chunk_size+1) * (chunk_size+1))
	normals.resize((chunk_size+1) * (chunk_size+1))
	triangles.resize((chunk_size) * (chunk_size) * 6)
	
	
	var i = 0
	var triangle_i = 0
	
	var topleft_x : float = (chunk_size) / 2.0
	var topleft_z : float = -topleft_x
	
	for z in range(chunk_size+1):
		for x in range(chunk_size+1):
			verts[i] = Vector3(topleft_x + x, noise.get_value(chunk_x + x, chunk_z + z) * height_multiplier, topleft_z + z)
			uvs[i] = Vector2(x / float(chunk_size+1), z / float(chunk_size+1))
			
			if(x < chunk_size and z < chunk_size):
				
				# First triangle of face
				triangles[triangle_i] = i
				triangles[triangle_i + 1] = i + chunk_size + 2
				triangles[triangle_i + 2] = i + chunk_size + 1
				
				# Second triangle of face
				triangles[triangle_i + 3] = i + chunk_size + 2
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
	mesh.surface_set_material(0, material_terrain)
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	mesh_instance.mesh = mesh
	
	# Costly line
	mesh_instance.create_trimesh_collision()
	
	for child in mesh_instance.get_children():
		child.visible = false

	
func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.material = material_water
	water_mesh.mesh = plane_mesh
	mesh_instance.translation = Vector3(mesh_instance.translation.x, chunk_water_offset, mesh_instance.translation.z)
