class_name Noise

"""
	Abstract class for noise generators.
	Each noise generator should implement these methods
"""
class NoiseGenerator:
	
	var noise_seed : int
	
	func _init(noise_seed: int):
		self.noise_seed = noise_seed
	
	func get_value(x: float, z: float) -> float:
		assert(false, "Abstract Method get_value() not implemented")
		return 0.0

"""
	Simplest form of noise generator.
	Uses OpenSimplex noise values and that's it
"""
class BasicGenerator:
	extends NoiseGenerator
	
	var simplex_noise : OpenSimplexNoise
	
	
	# Some basic values
	# period = 100
	# lacunarity = 7
	# octaves = 5
	# persistence = 0.2
	
	func _init(
			noise_seed=0, 
			octaves=3, 
			period=64.0, 
			lacunarity=2.0, 
			persistence=0.5
		).(noise_seed):
			
		self.simplex_noise = OpenSimplexNoise.new()
		self.simplex_noise.seed = noise_seed
		self.simplex_noise.period = period
		self.simplex_noise.octaves = octaves
		self.simplex_noise.lacunarity = lacunarity
		self.simplex_noise.persistence = persistence
	
	func get_value(x: float, z: float) -> float:
		return self.simplex_noise.get_noise_2d(x,z)
		
	func set_seed(new_seed: int):
		self.simplex_noise.seed = new_seed
		
	func set_period(period: float):
		self.simplex_noise.period = period
		
	func set_octaves(octaves: int):
		self.simplex_noise.octaves = clamp(octaves, 1, 9)
	
	func set_lacunarity(lacunarity: float):
		self.simplex_noise.lacunarity = lacunarity
	
	func set_persistence(persistence: float):
		self.simplex_noise.persistence = clamp(persistence, 0, 1)
		
	func get_image(size: int) -> Image:
		return self.simplex_noise.get_image(size, size)
