#ifndef CMAKEGDNATIVE_TESTCLASS_H
#define CMAKEGDNATIVE_TESTCLASS_H

#include <core/Godot.hpp>
#include <Node.hpp>

namespace godot {

    class TestClass : public Node {
    GODOT_CLASS(TestClass, Node)

    public:

        static void _register_methods();

        void _init() {}

        TestClass() = default;

        virtual ~TestClass();

        void hallo();

    };

}


#endif //CMAKEGDNATIVE_TESTCLASS_H
