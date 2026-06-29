extends Resource
class_name StatChange

enum Target { SELF, OPPONENT }

@export var stat: Enums.TecmonStat
@export_range(-6, 6) var stages: int = -1
@export var chance: int = 100
@export var target: Target = Target.OPPONENT
