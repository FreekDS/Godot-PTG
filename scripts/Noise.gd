class_name NoiseFunc

static func generate_noise_map(mapWidth: int, mapHeight: int, scale: float, noise: OpenSimplexNoise) -> Array:
	
	if scale <= 0:
		scale = 0.00001
	
	var map = []
	
	for y in range(mapHeight):
		var row = []
		for x in range(mapWidth):
			var sampleX: float = x / scale
			var sampleY: float = y / scale
			
			var noiseVal = noise.get_noise_2d(sampleX, sampleY)
			row.append(noiseVal)
			
		map.append(row)

	return map
