#include "MeshData.hpp"
#include "utils.hpp"

namespace godot {


    MeshData::MeshData(int size) : MeshData(size, size) {}

    MeshData::MeshData(Vector2 size) : size(size) {
        int actualSize = size.x * size.y;
        vertices.resize(actualSize);
        uvs.resize(actualSize);
        normals.resize(actualSize);
        triangles.resize(actualSize * 6);
    }

    MeshData::MeshData(int sizeX, int sizeY) : MeshData(Vector2((float) sizeX, (float) sizeY)) {}

    void MeshData::addVertex(size_t at, const Vector3 &vertex) {
        vertices[at] = vertex;
    }

    void MeshData::addUV(size_t at, const Vector2 &uv) {
        uvs[at] = uv;
    }

    int MeshData::createTrianglesAt(int triangleIndex, int vertexIndex) {

        int sizeX = static_cast<int>(size.x);

        if (vertexIndex + sizeX + 1 > 241 * 241) {
            Godot::print("Niet flink");
        }

        // Triangle 1
        triangles[triangleIndex] = vertexIndex;
        triangles[triangleIndex + 1] = vertexIndex + sizeX + 1;
        triangles[triangleIndex + 2] = vertexIndex + sizeX;

        // Triangle 2

        triangles[triangleIndex + 3] = vertexIndex + sizeX + 1;
        triangles[triangleIndex + 4] = vertexIndex;
        triangles[triangleIndex + 5] = vertexIndex + 1;
        return triangleIndex + 6;
    }

    // TODO: find a way to perform this while adding triangles
    void MeshData::calculateNormals() {
        for (int ti = 0; ti < triangles.size() / 3; ti++) {
            int triangleIndex = ti * 3;

            int index_a = triangles[triangleIndex];
            int index_b = triangles[triangleIndex + 1];
            int index_c = triangles[triangleIndex + 2];

            Vector3 a = vertices[index_a];
            Vector3 b = vertices[index_b];
            Vector3 c = vertices[index_c];

            Vector3 AB = b - a;
            Vector3 AC = c - a;

            Vector3 normal_value = AC.cross(AB).normalized();

            normals[index_a] += normal_value;
            normals[index_b] += normal_value;
            normals[index_c] += normal_value;
        }

        for (auto &n: normals) {
            n.normalize();
        }
    }

    Ref<ArrayMesh> MeshData::buildMesh() {
        if (mesh == nullptr) {
            PoolVector3Array pVertices = toPoolVector3(this->vertices);
            PoolVector3Array pNormals = toPoolVector3(this->normals);
            PoolVector2Array pUvs = toPoolVector2(this->uvs);
            PoolIntArray pTriangles = toPoolInt(this->triangles);

            godot::Array arrays;
            arrays.resize(ArrayMesh::ARRAY_MAX);
            arrays[ArrayMesh::ARRAY_VERTEX] = pVertices;
            arrays[ArrayMesh::ARRAY_NORMAL] = pNormals;
            arrays[ArrayMesh::ARRAY_TEX_UV] = pUvs;
            arrays[ArrayMesh::ARRAY_INDEX] = pTriangles;

            mesh = static_cast<Ref<ArrayMesh>>(ArrayMesh::_new());
            mesh->add_surface_from_arrays(ArrayMesh::PRIMITIVE_TRIANGLES, arrays);

            collisionShape = mesh->create_convex_shape(true, true);
        }

        return mesh;
    }

    Ref<Shape> MeshData::getShape() {
        if (collisionShape == nullptr) {
            buildMesh();
        }
        return collisionShape;
    }
}
