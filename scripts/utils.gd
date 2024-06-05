static func Scale6(value: Vector3,
 posX: float, negX: float,
 posY: float, negY: float,
 posZ: float, negZ: float) -> Vector3:
	var result := value
	if result.x > 0:
		result.x *= posX
	elif result.x < 0:
		result.x *= negX
	
	if result.y > 0:
		result.y *= posY
	elif result.y < 0:
		result.y *= negY
	
	if result.z > 0:
		result.z *= posZ
	elif result.z < 0:
		result.z *= negZ
	
	return result

static func map_val(v, a1, a2, b1, b2):
	return clamp(((b2-b1)/(a2-a1))*(v-a1)+b1, b1, b2)
