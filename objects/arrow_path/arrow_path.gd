extends Path3D

@export var width: float = 1
@export var height: float = 1
@export var material: Material

@onready var mesh_instance = $MeshInstance3D
@onready var label = $Label3D

var start: Vector3
var end: Vector3
var text: String

func _ready():
	start = Vector3(0, 0, 1)
	end = Vector3(0, 0, -1)

func _process(delta):
	_bake()

func _bake():
	var local_start := to_local(start)
	var local_end := to_local(end)
	
	if curve.get_point_position(0) == local_start and \
		curve.get_point_position(1) == local_end:
		return
	
	label.text = text
	
	var mesh := mesh_instance.mesh as ImmediateMesh
	
	curve.set_point_position(0, local_start)
	curve.set_point_out(0, Vector3(0, height, 0))
	curve.set_point_position(1, local_end)
	var length := curve.get_baked_length()
	
	mesh.clear_surfaces()
	
	if length == 0:
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var add_step := func (dist: float):
		var xform := curve.sample_baked_with_rotation(dist)
		var u := (dist - (length - width)) / width
		
		mesh.surface_set_uv(Vector2(u, 0))
		mesh.surface_add_vertex(xform * Vector3(-width/2.0, 0, 0))
		mesh.surface_set_uv(Vector2(u, 1))
		mesh.surface_add_vertex(xform * Vector3(width/2.0, 0, 0))
	
	for i in range(int(length / curve.bake_interval)):
		var dist := i * curve.bake_interval
		add_step.call(dist)
	
	add_step.call(length)
	
	mesh.surface_end()
	mesh.surface_set_material(0, material)
	


func _on_visibility_changed():
	process_mode = PROCESS_MODE_INHERIT if visible else PROCESS_MODE_DISABLED
	if visible:
		_bake()
