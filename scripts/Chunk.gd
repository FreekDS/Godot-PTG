tool
extends Spatial

var mesh_instance : MeshInstance
var noise : OpenSimplexNoise = OpenSimplexNoise.new()

# Visible in editor
export(int) var chunk_seed = randi() setget set_chunk_seed
export var chunk_x : float = 1 setget set_chunk_x
export var chunk_z : float = 1 setget set_chunk_z
export(bool) var chunk_generate_water = false setget set_generate_water
export(int, 1, 500) var chunk_size = 16 setget set_chunk_size

export(float) var chunk_water_offset = 0 setget set_water_offset

export var material_terrain : Material setget set_material
export var material_water : Material


export(int,100) var noise_frequency = 100 setget set_frequency
export(float) var noise_lacunarity = 1 setget set_lacunarity
export(int, 1, 9) var noise_octaves = 1 setget set_octaves
export(float) var noise_persistence = 1 setget set_persistence


func set_frequency(value):
	noise_frequency = value
	noise.period = noise_frequency
	_trigger_update()

func set_lacunarity(value):
	noise_lacunarity = value
	noise.lacunarity = noise_lacunarity
	_trigger_update()
	
func set_octaves(value):
	noise_octaves = value
	noise.octaves = noise_octaves
	_trigger_update()

func set_persistence(value):
	noise_persistence = value
	noise.persistence = noise_persistence
	_trigger_update()

func set_water_offset(value):
	chunk_water_offset = value
	if chunk_generate_water:
		chunk_generate_water()
	elif get_node_or_null("WaterMesh") != null:
		$WaterMesh.queue_free()

func set_material(value):
	material_terrain = value
	_trigger_update()

func _trigger_update():
	if mesh_instance == null:
		mesh_instance = $TerrainMesh
		return
	for child in mesh_instance.get_children():
		child.queue_free()
	
	generate_chunk()
	if chunk_generate_water:
		chunk_generate_water()
	elif get_node_or_null("WaterMesh") != null:
		$WaterMesh.queue_free()

func set_chunk_x(value):
	chunk_x = value
	_trigger_update()

func set_chunk_z(value):
	chunk_z = value
	_trigger_update()

func set_generate_water(value):
	chunk_generate_water = value
	_trigger_update()

func set_chunk_size(value):
	chunk_size = value
	_trigger_update()

func set_chunk_seed(value):
	chunk_seed = value
	_trigger_update()


func _initialize():
	pass


var rotation_haha = 0.2
var timing = 0

func _process(delta):
	
	
	
	if timing > 10:
		var chance = rand_range(0, 100)
		if chance <0:
			rotation_haha = -rotation_haha
		timing = 0
	
	if not Engine.editor_hint:
		$TerrainMesh.rotate_y(rotation_haha * delta)
	
	timing += delta	


#func _ready():
#	_trigger_update()
#	noise = OpenSimplexNoise.new()
	
func generate_chunk():
	# TODO: rewrite such that it uses array meshes
	# for even faster execution
	
	noise.seed = chunk_seed
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
		
		vertex.y = noise.get_noise_2d(vertex.x + chunk_x, vertex.z + chunk_z) * 80
		
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

	
func chunk_generate_water():
	for child in get_children():
		if 'WaterMesh' in child.name:
			if not child.is_queued_for_deletion():
				child.queue_free()
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.material = material_water
	var mesh_instance = MeshInstance.new()
	mesh_instance.name = "WaterMesh"
	mesh_instance.mesh = plane_mesh
	mesh_instance.translation = Vector3(mesh_instance.translation.x, chunk_water_offset, mesh_instance.translation.z)
	add_child(mesh_instance)
	if Engine.editor_hint:
		mesh_instance.set_owner(get_tree().edited_scene_root)
