#ifndef CMAKELIBRARYTEST_MESHDATA_HPP
#define CMAKELIBRARYTEST_MESHDATA_HPP

// GODOT INCLUDES
#include <Vector3.hpp>
#include <Vector2.hpp>
#include <ArrayMesh.hpp>
#include <PoolArrays.hpp>
#include <Shape.hpp>

// STD INCLUDES
#include <vector>

namespace godot {

    class MeshData {
        std::vector<Vector3> vertices;
        std::vector<Vector3> normals;
        std::vector<Vector2> uvs;
        std::vector<int> triangles;

        Vector2 size;
        Ref<ArrayMesh> mesh = nullptr;
        Ref<Shape> collisionShape = nullptr;

    public:

        MeshData() = default;

        /**
         * Constructor
         * @param size: initialize size at Vector2(Size, Size)
         */
        MeshData(int size);

        /**
         * Constructor
         * @param size initialize size
         */
        MeshData(Vector2 size);

        /**
         * Constructor
         * @param sizeX initialize x size
         * @param sizeY initialize y size
         */
        MeshData(int sizeX, int sizeY);

        /**
         * Destructor
         */
        ~MeshData() = default;

        /**
         * Add vertex at certain position
         * @param at index to put vertex at
         * @param vertex vertex to add
         */
        void addVertex(size_t at, const Vector3& vertex);

        /**
         * Add UV at certain position
         * @param at index to put UV at
         * @param uv UV to add
         */
        void addUV(size_t at, const Vector2& uv);

        /**
         * Create the triangles based on a vertex
         * @param triangleIndex Current triangle index
         * @param vertexIndex Current vertex index
         * @return new triangle index
         */
        int createTrianglesAt(int triangleIndex, int vertexIndex);

        /**
         * Calculate the normals based on the vertices and triangles
         */
        void calculateNormals();

        /**
         * Convert the MeshData into a Godot ArrayMesh
         * @return Reference to the Godot ArrayMesh
         */
        Ref<ArrayMesh> buildMesh();

        Ref<Shape> getShape();

    };

} // namespace godot


#endif //CMAKELIBRARYTEST_MESHDATA_HPP
