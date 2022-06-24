#include "TestClass.hpp"

void godot::TestClass::hallo() {
    Godot::print("Hallo, ik kom vanuit het leuke gdscript gebuild met het geweldige CMake dan nog!!");
}

void godot::TestClass::_register_methods() {
    godot::register_method("hello", &godot::TestClass::hallo);
}

godot::TestClass::~TestClass() {}
