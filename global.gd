extends Node

var enemy_num := {1: 20,
				  2: 20,
				  3: 15,
				  4: 40};

var enemy_list := {1: ["orca", "lamprey"],
				   2: ["lamprey"],
				   3: ["lamprey"],
				   4: ["tranq", "harpoon", "ultrasonic"]};

var obstacle_list := {1: ["wood", "glass"],
					  2: ["mine", "glass"],
					  3: ["glass", "barrel", "wood", "net", "plastic"],
					  4: ["glass", "wood", "net"]};

var stage_water_color := {1: Color(0, 0.96, 1, 0.3),
						  2: Color(0, 0.4, 0.83, 0.3),
						  3: Color(0.16, 0.61, 0.46, 0.31),
						  4: Color(0, 0.4, 0.83, 0.3)};

var stage_water_darkness := {1: 0.5,
							 2: 0,
							 3: 1,
							 4: 1};

var enemy_pos_y := {};#scuba diver

var obstacle_pos_y := {"glass": "rand",
					   "wood": "rand",
					   "plastic": "rand",
					   "barrel": "rand",
					   "net": "rand",
					   "mine": 417};

var character = "male";

var stage = 1;

var final_stage = 4;

var player_level = 0;

var paused := false;

var skip_tut := false;
