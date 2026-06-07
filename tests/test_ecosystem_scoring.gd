extends GutTest


func test_grade_thresholds() -> void:
	assert_eq(EcosystemScoring._score_to_grade(95.0), "S")
	assert_eq(EcosystemScoring._score_to_grade(90.0), "S")
	assert_eq(EcosystemScoring._score_to_grade(89.9), "A")
	assert_eq(EcosystemScoring._score_to_grade(75.0), "A")
	assert_eq(EcosystemScoring._score_to_grade(74.9), "B")
	assert_eq(EcosystemScoring._score_to_grade(60.0), "B")
	assert_eq(EcosystemScoring._score_to_grade(59.9), "C")
	assert_eq(EcosystemScoring._score_to_grade(40.0), "C")
	assert_eq(EcosystemScoring._score_to_grade(39.9), "D")
	assert_eq(EcosystemScoring._score_to_grade(0.0), "D")


func test_grade_multipliers() -> void:
	assert_eq(EcosystemScoring.GRADE_MULTIPLIERS["S"], 2.0)
	assert_eq(EcosystemScoring.GRADE_MULTIPLIERS["A"], 1.5)
	assert_eq(EcosystemScoring.GRADE_MULTIPLIERS["B"], 1.0)
	assert_eq(EcosystemScoring.GRADE_MULTIPLIERS["C"], 0.75)
	assert_eq(EcosystemScoring.GRADE_MULTIPLIERS["D"], 0.5)


func test_weights_sum_to_one() -> void:
	var total: float = EcosystemScoring.THROUGHPUT_WEIGHT + EcosystemScoring.DIVERSITY_WEIGHT + EcosystemScoring.SUSTAINABILITY_WEIGHT
	assert_almost_eq(total, 1.0, 0.001)
