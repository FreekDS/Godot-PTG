class_name HeightRes extends Resource

export(OpenSimplexNoise) var noise: OpenSimplexNoise
export(Curve) var height_influence: Curve
export(float) var flat_height_multiplier = 1.0
export(float) var default_height


func _init(
	noise = null, 
	height_influence = null, 
	height_multiplier = 1.0,
	default_height = 0.0	
):	
	if not height_influence:
		self.height_influence = Curve.new()
	else:
		self.height_influence = height_influence
	
	self.default_height = default_height
	self.flat_height_multiplier = 1.0


func get_height(x, y):
	if not noise:
		return self.default_height
	self.noise.lacunarity = 7
	var sample = noise.get_noise_2d(x, y)
	var height_influence = self.height_influence.interpolate(sample)
	return sample * height_influence * flat_height_multiplier + default_height
