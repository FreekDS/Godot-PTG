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
	
	var array_mesh = ArrayMesh.new()

	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)

	var vertices = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var triangles = PoolIntArray()

	triangles.resize(self.size * self.size * 6)
	normals.resize(self.size * self.size)
	vertices.resize(self.size * self.size)
	uvs.resize(self.size * self.size)
	
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
			
			vertices[v_i] = vert
			uvs[v_i] = uv
			
			# 1 face == 2 triangles
			if x < self.size - 1 and z < self.size - 1:

				# triangle 1
				triangles[t_i] = v_i
				triangles[t_i + 1] = v_i + self.size + 1
				triangles[t_i + 2] = v_i + self.size 

				# triangle 2
				triangles[t_i + 3] = v_i + self.size + 1
				triangles[t_i + 4] = v_i
				triangles[t_i + 5] = v_i + 1
#
				t_i += 6
			v_i += 1

	# Calculate normals :)
	for ti in range(triangles.size() / 3):

		var triangle_index = ti * 3

		var index_a = triangles[triangle_index]
		var index_b = triangles[triangle_index + 1]
		var index_c = triangles[triangle_index + 2]

		var a: Vector3 = vertices[index_a]
		var b: Vector3 = vertices[index_b]
		var c: Vector3 = vertices[index_c]

		var AB = b - a
		var AC = c - a

		var normal_value = AC.cross(AB).normalized()

		normals[index_a] += normal_value
		normals[index_b] += normal_value
		normals[index_c] += normal_value

	# Normalize normals
	for i in range(len(normals)):
		normals[i] = normals[i].normalized()

	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_INDEX] = triangles
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
