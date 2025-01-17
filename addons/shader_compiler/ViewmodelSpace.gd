@tool
extends ShaderSpace
class_name ViewmodelSpace
## This node will configure all meshes childed inside of it (recursively) to act without clipping through wall, useful for wieldable viewmodels to keep them in-front
## 
## Useful for viewmodels for wieldables. Can toggle the clipping behavior by setting `disable_viewmodel_clipping`

@export var viewmodel_fov: float  = 75.0 :
	get:
		return viewmodel_fov
	set(value):
		RenderingServer.global_shader_parameter_set("viewmodel_fov", value)
		viewmodel_fov = value

## When this is checked, it will make it so any childed viewmodel will always be rendered in front of everything else
@export var disable_viewmodel_clipping : bool = true:
	get:
		return disable_viewmodel_clipping
	set(value):
		set_instance_shader_parameter("viewmodel_enabled", value)
		disable_viewmodel_clipping = value

func _init():
	RenderingServer.global_shader_parameter_add("viewmodel_fov", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, viewmodel_fov)
	injected_vars = '''
	global uniform float viewmodel_fov = 75.0f;
	instance uniform bool viewmodel_enabled = true;'''

	injected_vertex = '''
		/* begin shader magic*/
		float onetanfov = 1.0f / tan(0.5f * (viewmodel_fov * PI / 180.0f));
		float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
		// modify projection matrix to match FOV
		PROJECTION_MATRIX[1][1] = -onetanfov;
		PROJECTION_MATRIX[0][0] = onetanfov / aspect;
		// this next part draws the viewmodel over everything (disable if you want dof near on viewmodel)
			
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
		
		if(viewmodel_enabled){
			POSITION.z = mix(POSITION.z, 0, -2.999);
		}
		/* end shader magic */
	'''

func convert_surfaces():
	super()
	if not disable_viewmodel_clipping:
		set_instance_shader_parameter("viewmodel_enabled",disable_viewmodel_clipping)
