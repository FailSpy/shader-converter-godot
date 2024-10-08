# Shader Precompiler and Converter for Godot 4

This Godot addon allows you to efficiently convert any `StandardMaterial3D` in your scene into a material that you can alter the shader code of, as well as the ability to on-demand compile shaders to minimize performance stutters when said materials are first displayed to the camera.

The main component is the `ShaderSpace` node, which automatically converts all `StandardMaterial3D` instances under its hierarchy to `ConvertedStandardMaterial3D`, keeping all set properties, which provides the ability to access and alter the shader code. 

Once converted, you can either programmatically inject your code (see `ViewmodelSpace`), or bake it in and alter it by hand.

Additionally, the `ShaderPrecompiler` node ensures that shaders are precompiled when the `precompile` function is called with a `ShaderMaterial` by displaying it invisibly to the MainCamera, forcing the engine to compile it.

This addon's main trick is replicating in pure GDScript the material shader generation code from the [Godot C++ source code](https://github.com/godotengine/godot/blob/da945ce6266ce27ba63b6b08dc0eb2414594f7cb/scene/resources/material.cpp#L674-L1527) based on StandardMaterial3D's properties for converting. The GDScript implementation of the Shader generation code is in `Material3DConversion.gd`, which converts any `StandardMaterial3D` to the custom `ConvertedStandardMaterial3D`. You can bake in those changes if you'd like, but be weary of making changes to the material as converting it back won't save your changes.

## Features

- **Shader Injection**: Easily inject custom variables and shader code into existing `StandardMaterial3D` instances.
- **Shader Precompilation**: Force the precompilation of shaders when the scene loads which minimizes runtime stuttering from JIT compilation by forcing it into view early in the scene's initialization (or when requested)
- **Extensibility**: You can create new nodes to apply specific shader logic to all objects in the hierarchy, e.g., viewmodels for FPS games that should not clip through walls.

## Usage

### ViewmodelSpace Example

`ViewmodelSpace.gd` is an example of how to extend `ShaderSpace` for a specific shader injection use case.

The `ViewmodelSpace` node injects some basic vertex code that modifies the viewmodel rendering to prevent it from clipping through walls. You add `StandardMaterial3D`-based objects under its hierarchy, and the ViewmodelSpace will inject the Viewmodel shader code into all of them.

The Viewmodel shader code renders to the camera on top of everything else in the Z buffer. It also includes a viewmodel FOV parameter [like in 2nafish117's implementation](https://www.youtube.com/watch?v=NF-U5J92ivk)

This is useful for FPS where you have a weapon or other handheld object in front of the camera and want to prevent it from clipping, and/or have the viewmodel render at its own FOV, independent of the camera's FOV.

### ShaderSpace

The `ShaderSpace` node is the main interface for converting and injecting shader code into `StandardMaterial3D`. You can create a `ShaderSpace` node in the scene and add any number of meshes or geometry as its children. The script will automatically handle the conversion and shader injection for all the children nodes.

Here is a basic example of how to use `ShaderSpace`:

1. **Create a `ShaderSpace` node** in your scene.
2. **Add meshes** as children of the `ShaderSpace`.
3. **Inject custom shader code** by modifying the `injected_vars` and `injected_vertex` properties.

```gdscript
@tool
extends ShaderSpace

# Example of injecting custom shader code into all child meshes
func _init():
    injected_vars = '''
    uniform float custom_uniform = 1.0;'''
    
    injected_vertex = '''
    VERTEX *= custom_uniform;'''
```

### Properties

- `precompile_on_enter`: If set to `true`, it will precompile all shaders when this node enters the scene, reducing in-game stutter caused by shader compilation.
- `bake`: If set to `true`, materials are converted in the scene to the `ConvertedStandardMaterial3D` form. However, any changes made to the baked materials upon un-baking will be lost.

### ShaderPrecompiler

`ShaderPrecompiler` is a utility that forces shaders to be compiled on-demand, instead of compiling the first time the camera encounters the material (causing stuttering).

Use `ShaderPrecompiler.precompile(tree, shader: ShaderMaterial)` inside any node where you want to ensure the shader is precompiled.

Example usage within `ShaderSpace`:

```gdscript
if precompile_on_enter:
    ShaderPrecompiler.precompile(get_tree(), new_shader_material)
```

### API Reference

#### `ShaderSpace`

- `precompile_on_enter (bool)`: Precompile shaders when the node enters the scene.
- `bake (bool)`: Bake converted material resources into the scene. Unbaked materials are only generated when the node enters the scene.
- `injected_vars (String)`: Custom shader variable declarations to inject into converted `ShaderMaterial`.
- `injected_vertex (String)`: Custom vertex shader code to inject.

#### `ShaderPrecompiler`

- `precompile(tree: SceneTree, shader: ShaderMaterial, use_new_node: bool = false)`: Precompile the specified shader material.
  - `tree`: The scene tree where shaders will be precompiled.
  - `shader`: The shader material to precompile.
  - `use_new_node`: If `true`, a new node is used for precompilation.

This flag will trigger precompilation for any converted `ShaderMaterial` when the node enters the scene.

## Known Limitations

- MultiMeshInstances and Particles are not yet supported.

## Contributing

If you'd like to contribute or report issues, please open a pull request or issue on the GitHub repository for this project.

## License

This addon is available under the MIT License. See the LICENSE file for more information.
