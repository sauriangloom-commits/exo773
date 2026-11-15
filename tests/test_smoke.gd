extends GutTest

func test_runner_boots() -> void:
	assert_eq(1 + 1, 2, "Arithmetic still works")

func test_project_autoload_present() -> void:
	assert_not_null(Game, "Game autoload is available inside tests")
