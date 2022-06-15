class_name MeshData


var vertices = PoolVector3Array()
var normals = PoolVector3Array()
var triangles = PoolIntArray()
var uvs = PoolVector2Array()

#var vertices = []
#var normals = []
#var triangles = []
#var uvs = []

var size: Vector2
var mesh: Mesh = null



func _init(size_x, size_y):
	self.size = Vector2(size_x, size_y)
	var total_size = size_x * size_y
	vertices.resize(total_size)
	normals.resize(total_size)
	uvs.resize(total_size)
	triangles.resize(total_size * 6)


func add_vertex(at: int, new_v: Vector3):
	self.vertices[at] = new_v
	
func add_uv(at: int, new_uv: Vector2) -> Vector2:
	self.uvs[at] = new_uv
	return new_uv
	
func create_triangles_at(v_i: int, t_i: int):
	# Triangles
	triangles[t_i] = v_i
	triangles[t_i + 1] = v_i + self.size.x + 1
	triangles[t_i + 2] = v_i + self.size.x
	
	# triangle 2
	triangles[t_i + 3] = v_i + self.size.x + 1
	triangles[t_i + 4] = v_i
	triangles[t_i + 5] = v_i + 1

	return t_i + 6
	
func calculate_normals():
	for ti in range(self.triangles.size() / 3):
		
		var triangle_index = ti * 3
		
		var index_a = self.triangles[triangle_index]
		var index_b = self.triangles[triangle_index + 1]
		var index_c = self.triangles[triangle_index + 2]
		
		var a: Vector3 = self.vertices[index_a]
		var b: Vector3 = self.vertices[index_b]
		var c: Vector3 = self.vertices[index_c]

		var AB = b - a
		var AC = c - a

		var normal_value = AC.cross(AB).normalized()

		self.normals[index_a] += normal_value
		self.normals[index_b] += normal_value
		self.normals[index_c] += normal_value

	# Normalize normals
	for i in range(len(normals)):
		self.normals[i] = self.normals[i].normalized()
	

func build_mesh() -> Mesh:
	if not self.mesh:
		var arrays = []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = self.vertices
		arrays[ArrayMesh.ARRAY_TEX_UV] = self.uvs
		arrays[ArrayMesh.ARRAY_NORMAL] = self.normals
		arrays[ArrayMesh.ARRAY_INDEX] = self.triangles
		
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		self.mesh = array_mesh
		
	
	return self.mesh

