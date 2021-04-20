extends Node

func is_between_inclusive(value:float, min_range:float, max_range:float):
	return value <= max_range and value >= min_range
	
func is_between_exclusive(value:float, min_range:float, max_range:float):
	return value < max_range and value > min_range
