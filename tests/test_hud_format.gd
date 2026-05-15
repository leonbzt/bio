extends GutTest


func test_abbreviate_under_1k() -> void:
	assert_eq(FormatUtils.abbreviate(847.0), "847")


func test_abbreviate_thousands() -> void:
	assert_eq(FormatUtils.abbreviate(1499.0), "1.5K")
	assert_eq(FormatUtils.abbreviate(12_345.0), "12.3K")


func test_abbreviate_millions_and_billions() -> void:
	assert_eq(FormatUtils.abbreviate(1_500_000.0), "1.5M")
	assert_eq(FormatUtils.abbreviate(2_500_000_000.0), "2.5B")


func test_abbreviate_trillions() -> void:
	assert_eq(FormatUtils.abbreviate(1_200_000_000_000.0), "1.2T")
