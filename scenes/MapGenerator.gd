extends Control

export var mapWidth: int = 50
export var mapHeight: int = 50

export var noiseScale: float
onready var TextureObj = $TextureRect

export var gen_new = false setget trigger_gen

export var noise_seed = 10
export var noise_lacunarity = .2
export var noise_octaves = 3
export(float, 0, 1) var noise_persistance = .5
export var noise_period = 10
export var noise_nogiet = 3

export(Curve) var jep


var TERRAIN_COLORS = {
	0: Color("#238FD6"),
	.60: Color("#136100"),
	1: Color.white
}


var noise = OpenSimplexNoise.new()


func trigger_gen(_value):
	if TextureObj:
		GenerateMap()

func _ready():
	GenerateMap()

func GenerateMap():
	var noiseMap = NoiseFunc.generate_noise_map(mapWidth, mapHeight, noiseScale, noise)
	
	var colorMap = []
	for y in range(len(noiseMap)):
		var colorRow = []
		for x in range(len(noiseMap[0])):
			var height = noiseMap[x][y]
			for keyVal in TERRAIN_COLORS.keys():
				if height > .8:
					print("Jep cock")
				if height <= keyVal:
					colorRow.append(TERRAIN_COLORS[keyVal])
					break
		colorMap.append(colorRow)
				
	DrawNoiseMap(noiseMap, colorMap)


func DrawNoiseMap(noiseMap, colorMap):
	var width = len(noiseMap)
	var height = len(noiseMap[1])
	
	var textIm = Image.new()
	textIm.create(width, height, true, Image.FORMAT_RGBF)
	
	textIm.lock()
	for y in range(height):
		for x in range(width):
			textIm.set_pixel(x, y, lerp(Color.black, Color.white, (noiseMap[x][y] + 1) / 2))
			textIm.set_pixel(x, y, colorMap[x][y])
	textIm.unlock()
			
	TextureObj.texture = ImageTexture.new()
	TextureObj.texture.create_from_image(textIm)
	
