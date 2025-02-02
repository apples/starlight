@tool
class_name InsetQuadMesh
extends PrimitiveMesh

@export var orientation: PlaneMesh.Orientation = PlaneMesh.Orientation.FACE_Z:
	set(v):
		if orientation == v: return
		orientation = v
		request_update()

@export var size: Vector2 = Vector2(1, 1):
	set(v):
		if size == v: return
		size = v
		request_update()

@export var left: float = 0.1:
	set(v):
		if left == v: return
		left = v
		request_update()

@export var top: float = 0.1:
	set(v):
		if top == v: return
		top = v
		request_update()

@export var right: float = 0.1:
	set(v):
		if right == v: return
		right = v
		request_update()

@export var bottom: float = 0.1:
	set(v):
		if bottom == v: return
		bottom = v
		request_update()

func _create_mesh_array() -> Array:
	var start_pos: Vector2 = size * -0.5
	
	var normal := Vector3(0.0, 1.0, 0.0)
	if orientation == PlaneMesh.Orientation.FACE_X:
		normal = Vector3(1.0, 0.0, 0.0)
	elif orientation == PlaneMesh.Orientation.FACE_Z:
		normal = Vector3(0.0, 0.0, 1.0)
	
	var tangent := [1.0, 0.0, 0.0, 1.0]
	if orientation == PlaneMesh.Orientation.FACE_X:
		tangent = [0.0, 0.0, -1.0, 1.0]
	
	var points: PackedVector3Array
	var normals: PackedVector3Array
	var tangents: PackedFloat32Array
	var uvs: PackedVector2Array
	var indices: PackedInt32Array
	
	points = [
		Vector3(size.x * -0.5 + left, size.y * 0.5 - top, 0.0),
		Vector3(size.x * -0.5,        size.y * 0.5, 0.0),
		Vector3(size.x * 0.5 - right, size.y * 0.5 - top, 0.0),
		Vector3(size.x * 0.5,         size.y * 0.5, 0.0),
		Vector3(size.x * 0.5 - right, size.y * -0.5 + bottom, 0.0),
		Vector3(size.x * 0.5,         size.y * -0.5, 0.0),
		Vector3(size.x * -0.5 + left, size.y * -0.5 + bottom, 0.0),
		Vector3(size.x * -0.5,        size.y * -0.5, 0.0),
	]
	
	if orientation == PlaneMesh.Orientation.FACE_X:
		for i in 8:
			points[i] = Vector3(0.0, points[i].y, -points[i].x)
	elif orientation == PlaneMesh.Orientation.FACE_Y:
		for i in 8:
			points[i] = Vector3(points[i].x, 0.0, -points[i].y)
	
	uvs = [
		Vector2(0.0 + left / size.x, 0.0 + top / size.y),
		Vector2(0.0, 0.0),
		Vector2(1.0 - right / size.x, 0.0 + top / size.y),
		Vector2(1.0, 0.0),
		Vector2(1.0 - right / size.x, 1.0 - bottom / size.y),
		Vector2(1.0, 1.0),
		Vector2(0.0 + left / size.x, 1.0 - bottom / size.y),
		Vector2(0.0, 1.0),
	]
	
	#  1--------3
	#  |\      /|
	#  | 0----2 |
	#  | |    | |
	#  | 6----4 |
	#  |/      \|
	#  7--------5
	
	indices = [
		0, 1, 3,
		3, 2, 0,
		2, 3, 5,
		5, 4, 2,
		4, 5, 7,
		7, 6, 4,
		6, 7, 1,
		1, 0, 6,
	]
	
	for i in 8:
		normals.append(normal)
		tangents.append_array(tangent)
	
	var arrs = []
	arrs.resize(Mesh.ARRAY_MAX)
	
	arrs[Mesh.ARRAY_VERTEX] = points
	arrs[Mesh.ARRAY_NORMAL] = normals
	arrs[Mesh.ARRAY_TANGENT] = tangents
	arrs[Mesh.ARRAY_TEX_UV] = uvs
	arrs[Mesh.ARRAY_INDEX] = indices
	
	return arrs
