@tool
class_name EnvironmentGenerator extends Node3D

@export var foliage_chunks: int = 10
@export var terrain_subdivisions: int = 1000
@export var terrain_scale: float = 1.0
@export var terrain_shader: ShaderMaterial = null
@export_tool_button("Generate", "Callable") var generate_action = generate

func generate():
	var gen_seed = int(randf() * 1000)

	var biomes = _generate_biomes(gen_seed)
	_generate_terrain(gen_seed, biomes)
	_generate_foliage(gen_seed, biomes)

func _generate_biomes(gen_seed: int) -> Texture2D:
	var biome_r = _generate_biome_channel(gen_seed, $BiomeR)
	var biome_g = _generate_biome_channel(gen_seed, $BiomeG)
	var biome_b = _generate_biome_channel(gen_seed, $BiomeB)

	for x in terrain_subdivisions:
		for z in terrain_subdivisions:
			var color = Color(
				biome_r.get_pixel(x, z).r,
				biome_g.get_pixel(x, z).r,
				biome_b.get_pixel(x, z).r
			)
			biome_r.set_pixel(x, z, color)

	return ImageTexture.create_from_image(biome_r)

func _generate_foliage(gen_seed: int, biomes: Texture2D):
	var foliage_root = $Foliage
	for child in foliage_root.get_children():
		foliage_root.remove_child(child)

	var terrain_size = terrain_subdivisions * terrain_scale
	var size = (terrain_scale * terrain_subdivisions) / foliage_chunks
	for x in foliage_chunks:
		for z in foliage_chunks:
			var chunk = load("res://environment/foliage/foliage_volume.tscn").instantiate()
			var shape = BoxShape3D.new()
			shape.size = Vector3(size, 100.0, size)
			chunk.find_child("Shape").shape = shape
			chunk.position = Vector3((x + 0.5) * size, 0.0, (z + 0.5) * size)
			chunk.configure(biomes, global_position, terrain_size)

			foliage_root.add_child(chunk)
			chunk.owner = get_tree().edited_scene_root

			#chunk.generate()

func _generate_terrain(gen_seed: int, biomes: Texture2D):
	var heights = $Heights
	var mesh_node = $Mesh
	heights.before_sampling(gen_seed)

	var heights_tex = ImageTexture.create_from_image(heights.to_image(terrain_subdivisions))

	var mesh = _generate_terrain_mesh(heights)
	var shader_inst = terrain_shader.duplicate()
	mesh.surface_set_material(0, shader_inst)
	mesh_node.mesh = mesh

	for child in mesh_node.get_children():
		mesh_node.remove_child(child)
	mesh_node.create_trimesh_collision()

	shader_inst.set_shader_parameter("heights", heights_tex)
	shader_inst.set_shader_parameter("biomes", biomes)

func _generate_biome_channel(gen_seed: int, source: SourceNoise) -> Image:
	if source == null:
		source = SourceNoise.new()

	source.before_sampling(gen_seed)
	return source.to_image(terrain_subdivisions)

func _generate_terrain_mesh(heights: SourceNoise):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = []

	var uvs = []
	for z in range(terrain_subdivisions + 1):
		for x in range(terrain_subdivisions + 1):
			var height = heights.sample(x, z)

			var vertex = Vector3(x, height, z) * terrain_scale
			vertices.append(vertex)

			var uv = Vector2(
				float(x) / terrain_subdivisions,
				float(z) / terrain_subdivisions
			)
			uvs.append(uv)
	
	for z in range(terrain_subdivisions):
		for x in range(terrain_subdivisions):
			var i = z * (terrain_subdivisions + 1) + x
			
			var v1 = vertices[i]
			var v2 = vertices[i + 1]
			var v3 = vertices[i + terrain_subdivisions + 1]
			
			var uv1 = uvs[i]
			var uv2 = uvs[i + 1]
			var uv3 = uvs[i + terrain_subdivisions + 1]
			
			var normal1 = (v2 - v1).cross(v3 - v1).normalized()
			
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv3)
			surface_tool.add_vertex(v3)
			
			var v4 = vertices[i + 1]
			var v5 = vertices[i + terrain_subdivisions + 2]
			var v6 = vertices[i + terrain_subdivisions + 1]
			
			var uv4 = uvs[i + 1]
			var uv5 = uvs[i + terrain_subdivisions + 2]
			var uv6 = uvs[i + terrain_subdivisions + 1]
			
			var normal2 = (v5 - v4).cross(v6 - v4).normalized()
			
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv4)
			surface_tool.add_vertex(v4)
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv5)
			surface_tool.add_vertex(v5)
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv6)
			surface_tool.add_vertex(v6)
	
	surface_tool.generate_normals()
	return surface_tool.commit()
