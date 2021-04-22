extends Spatial

class_name Chunk

onready var mesh_instance : MeshInstance = $TerrainMesh
onready var water_mesh : MeshInstance = $WaterMesh
var noise : Noise.NoiseGenerator

var chunk_x : float
var chunk_z : float

var chunk_generate_water = false setget set_generate_water
var chunk_size = 16 setget set_chunk_size

var chunk_water_offset = 0 setget set_water_offset

export var material_terrain : Material setget set_terrain_material
var material_water : Material


func update_size(new_size: int):
	self.chunk_size = new_size
	_trigger_update()

func update_noise(new_noise: Noise.NoiseGenerator):
	self.noise = new_noise

func _init(noise_generator: Noise.BasicGenerator, size, x, z):
	self.noise = noise_generator
	self.chunk_x = x
	self.chunk_z = z
	self.chunk_size = size
	
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

func generate_chunk():
	# TODO: rewrite such that it uses array meshes
	# for even faster execution

	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	
	plane_mesh.subdivide_depth = chunk_size * 0.5
	plane_mesh.subdivide_width = chunk_size * 0.5
	
	
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	
	surface_tool.create_from(plane_mesh, 0)
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane, 0)
	
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		vertex.y = noise.get_value(vertex.x + chunk_x, vertex.z + chunk_z) * 80
		data_tool.set_vertex(i, vertex)
		
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
		
	
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	surface_tool.add_smooth_group(true)
	surface_tool.append_from(array_plane, 0, Transform.IDENTITY)
	surface_tool.generate_normals()
	
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.mesh.surface_set_material(0, material_terrain)
	mesh_instance.create_trimesh_collision()
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	for child in mesh_instance.get_children():
		child.visible = false

	
func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.material = material_water
	water_mesh.mesh = plane_mesh
	mesh_instance.translation = Vector3(mesh_instance.translation.x, chunk_water_offset, mesh_instance.translation.z)
