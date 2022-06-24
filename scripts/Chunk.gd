extends Spatial
class_name Chunk

signal generation_done


# Chunk size: 241
# LOD possibilities (6):
# step sizes  1, 2, 4, 6, 8, 10, 12

const SCALE = 10
const size = 241
const LOD_COUNT = 6

var x: float
var z: float

var add_water: bool
var noise: OpenSimplexNoise

var LODLevel = 0
var LODMeshes = []

var h_contrib: Curve = null

var material = preload("res://terrain.material")
var water = preload("res://waterken.tres")


var heightGen: HeightRes = preload("res://TerrainGenerators/TestTerrain.tres")


var remove_me = false


func _init(
	noise: OpenSimplexNoise,
	x: float,
	z: float,
	heightContrib: Curve,
	LODLevel = 0
):
	self.add_water = false
	self.noise = noise
	self.x = x * (size -1)
	self.z = z * (size -1)
	self.LODLevel = LODLevel
	
	self.LODMeshes.resize(LOD_COUNT)
	self.h_contrib = heightContrib


func generate():
	"""Takes 353 ms"""

	var meshData = []
	meshData.resize(LOD_COUNT)

	print("Creating arrays... ", OS.get_ticks_msec())
	for i in range(LOD_COUNT):
		var lod = 1 if i == 0 else 2 * i
		var lod_mesh_size = (self.size-1) / lod + 1

		var vertices = PoolVector3Array()
		var uvs = PoolVector2Array()
		var normals = PoolVector3Array()
		var triangles = PoolIntArray()

		triangles.resize(lod_mesh_size * lod_mesh_size * 6)
		normals.resize(lod_mesh_size * lod_mesh_size)
		vertices.resize(lod_mesh_size * lod_mesh_size)
		uvs.resize(lod_mesh_size * lod_mesh_size)

		meshData[i] = {
			'vertices': vertices,
			'uvs': uvs,
			'normals': normals,
			'triangles': triangles,
			'v_i': 0,
			't_i': 0,
			'lod_size': lod_mesh_size
		}


	# var vertices = PoolVector3Array()
	# var uvs = PoolVector2Array()
	# var normals = PoolVector3Array()
	# var triangles = PoolIntArray()

	# triangles.resize(self.size * self.size * 6)
	# normals.resize(self.size * self.size)
	# vertices.resize(self.size * self.size)
	# uvs.resize(self.size * self.size)
	
	var v_is: Array = []
	var t_is: Array = []
	v_is.resize(LOD_COUNT)
	t_is.resize(LOD_COUNT)
	for i in range(LOD_COUNT):
		v_is[i] = 0
		t_is[i] = 0

	var v_i = 0
	var t_i = 0
	
	var topleft_x : float = -(self.size) / 2.0
	var topleft_z : float = topleft_x
	
	print("Creating mesh data... ", OS.get_ticks_msec())
	for z in range(self.size):
		for x in range(self.size):
			
			var vert = Vector3(
				topleft_x + x,
				noise.get_noise_2d(
					self.x + x, self.z + z
				),
				topleft_z + z
			)
			var interpol_val = (vert.y + 1) / 2.0
			interpol_val = vert.y
			vert.y = vert.y * self.h_contrib.interpolate(interpol_val) * 78

			#vert.y = heightGen.get_height(self.x + x, self.z + z)
			
			var uv = Vector2(
				x / float(self.size),
				z / float(self.size)
			)
			
			meshData[0]['vertices'][v_is[0]] = vert
			meshData[0]['uvs'][v_is[0]] = uv

			# vertices[v_i] = vert
			# uvs[v_i] = uv
			
			# 1 face == 2 triangles
			if x < meshData[0]['lod_size'] - 1 and z < meshData[0]['lod_size'] - 1:

				# triangle 1
				meshData[0]['triangles'][t_is[0]] = v_is[0]
				meshData[0]['triangles'][t_is[0] + 1] = v_is[0] + meshData[0]['lod_size'] + 1
				meshData[0]['triangles'][t_is[0] + 2] = v_is[0] + meshData[0]['lod_size'] 

				# triangle 2
				meshData[0]['triangles'][t_is[0] + 3] = v_is[0] + meshData[0]['lod_size'] + 1
				meshData[0]['triangles'][t_is[0] + 4] = v_is[0]
				meshData[0]['triangles'][t_is[0] + 5] = v_is[0] + 1

				t_is[0] += 6
			v_is[0] += 1
	
	print("Creating normals... ", OS.get_ticks_msec())

	# Calculate normals :)
	for ti in range(meshData[0]['triangles'].size() / 3):

		var triangle_index = ti * 3

		var index_a = meshData[0]['triangles'][triangle_index]
		var index_b = meshData[0]['triangles'][triangle_index + 1]
		var index_c = meshData[0]['triangles'][triangle_index + 2]

		var a: Vector3 = meshData[0]['vertices'][index_a]
		var b: Vector3 = meshData[0]['vertices'][index_b]
		var c: Vector3 = meshData[0]['vertices'][index_c]

		var AB = b - a
		var AC = c - a

		var normal_value = AC.cross(AB).normalized()

		meshData[0]['normals'][index_a] += normal_value
		meshData[0]['normals'][index_b] += normal_value
		meshData[0]['normals'][index_c] += normal_value

	# Normalize normals
	for i in range(len(meshData[0]['normals'])):
		meshData[0]['normals'][i] = meshData[0]['normals'][i].normalized()


	print("Applying mesh... ", OS.get_ticks_msec())
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(meshData[0]['vertices'])
	arrays[ArrayMesh.ARRAY_TEX_UV] = meshData[0]['uvs']
	arrays[ArrayMesh.ARRAY_NORMAL] = meshData[0]['normals']
	arrays[ArrayMesh.ARRAY_INDEX] = meshData[0]['triangles']

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance.new()
	add_child(m)
	m.mesh = array_mesh
	m.material_override = material
	m.create_trimesh_collision()
	self.name = "CHUNK (" + str(self.x) + ',' + str(self.z) + ")"
	self.transform.origin = Vector3(self.x * SCALE, 0, self.z * SCALE)
	self.scale = Vector3(SCALE, SCALE, SCALE)
	emit_signal("generation_done")
	
	var waterMesh = MeshInstance.new()
	waterMesh.mesh = PlaneMesh.new()
	waterMesh.mesh.surface_set_material(0, water)
	waterMesh.scale = Vector3(120, 120, 120)
	waterMesh.transform.origin.y -= 1
	add_child(waterMesh)


static func get_scaled_size():
	return SCALE * size

func generate_alternative():
	"""takes 14000ms !!! ????????"""
	var m_data = MeshData.new(size, size)
	
	var v_i = 0
	var t_i = 0
	
	var topleft_x : float = -(self.size) / 2.0
	var topleft_z : float = topleft_x
	
	for z in range(self.size):
		for x in range(self.size):
			
			var vert = Vector3(
				topleft_x + x,
				noise.get_noise_2d(
					self.x + x, self.z + z
				),
				topleft_z + z
			)
			var interpol_val = (vert.y + 1) / 2.0
			interpol_val = vert.y
			vert.y = vert.y * self.h_contrib.interpolate(interpol_val) * 78
			
			
			
			#vert.y = heightGen.get_height(self.x + x, self.z + z)
			
			var uv = Vector2(
				x / float(self.size),
				z / float(self.size)
			)
			m_data.add_vertex(v_i, vert)
			m_data.add_uv(v_i, uv)

			if x < self.size - 1 and z < self.size - 1:
				t_i = m_data.create_triangles_at(v_i, t_i)

			v_i += 1

	m_data.calculate_normals()
	var mesh = m_data.build_mesh()

	var m = MeshInstance.new()
	add_child(m)
	m.mesh = mesh
	m.material_override = material
	m.create_trimesh_collision()
	self.name = "CHUNK (" + str(self.x) + ',' + str(self.z) + ")"
	self.transform.origin = Vector3(self.x * SCALE, 0, self.z * SCALE)
	self.scale = Vector3(SCALE, SCALE, SCALE)
	emit_signal("generation_done")
	
	var waterMesh = MeshInstance.new()
	waterMesh.mesh = PlaneMesh.new()
	waterMesh.mesh.surface_set_material(0, water)
	waterMesh.scale = Vector3(120, 120, 120)
	waterMesh.transform.origin.y -= 1
	add_child(waterMesh)
