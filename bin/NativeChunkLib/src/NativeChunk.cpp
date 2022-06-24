#include "NativeChunk.hpp"
#include <string>

namespace godot {

    void godot::NativeChunk::generate() {

        // Generate all LOD levels
        for (int level = 0; level < LOD_COUNT; level++) {
            generateLOD(level);
        }

        // Trigger generation of all colliders
        for (int level = 0; level < LOD_COUNT; level++) {
            Ref<Mesh> mesh = meshes[level].buildMesh();
            meshInstance->set_mesh(mesh);
            meshInstance->switchCollider(level);
        }

        // Finally set LOD level to the required LOD level
        switchLOD(LOD, true);
    }

    void NativeChunk::hello() {
        Godot::print("NativeChunk greets the world from GDNative");
    }

    void NativeChunk::initialize(float x, float z, Ref<Resource> heightGenerator, unsigned int LOD, float scale) {

        std::string name = "CHUNK (" + std::to_string(x) + ',' + std::to_string(z) + ')';
        set_name(name.c_str());

        this->x = x * (SIZE - 1);
        this->z = z * (SIZE - 1);
        this->LOD = LOD;
        this->heightGenerator = heightGenerator;
        this->scaleFactor = scale;

        auto transform = get_transform();
        transform.set_origin(Vector3(this->x * scaleFactor, 0, this->z * scaleFactor));
        set_transform(transform);
    }

    void NativeChunk::setMaterial(Ref<Material> material) {
        terrainMaterial = material;
    }


    int NativeChunk::getSize() {
        return SIZE;
    }

    float NativeChunk::getScaledSize() {
        return SIZE * scaleFactor;
    }

    void NativeChunk::switchLOD(unsigned int level, bool bypass) {
        if (level == LOD && !bypass) {
            return;
        }
        LOD = level;
        Ref<Mesh> mesh = meshes[level].buildMesh();
        meshInstance->set_mesh(mesh);
        meshInstance->switchCollider(level);
        if (terrainMaterial != nullptr)
            meshInstance->set_material_override(terrainMaterial);
        set_scale(Vector3(scaleFactor, scaleFactor,
                          scaleFactor));
    }

    void NativeChunk::generateLOD(int level) {


        int vert_i = 0;
        int triangle_i = 0;

        float topleftX = -(float) SIZE / 2.f;
        float topLeftZ = topleftX;

        int stepSize = (level == 0) ? 1 : level * 2;
        int LODMeshSize = (SIZE - 1) / stepSize + 1;

        MeshData md{LODMeshSize};

        for (int z = 0; z < SIZE; z += stepSize) {
            for (int x = 0; x < SIZE; x += stepSize) {

                float height;
                if (heightGenerator != nullptr && heightGenerator->has_method("get_height")) {
                    height = heightGenerator->call("get_height", this->x + x, this->z + z);
                } else {
                    height = 0;
                }

                Vector3 vertex = Vector3(
                        topleftX + x,
//                        noise->get_noise_2d(this->x + x, this->z + z),
                        height,
                        topLeftZ + z
                );

//                float interpolated = (vertex.y + 1.f) / 2.0f;
//                interpolated = vertex.y;
//                vertex.y = vertex.y * heightContribution->interpolate(interpolated) * 78;

                Vector2 uv = Vector2(
                        x / float(SIZE),
                        z / float(SIZE)
                );

                md.addVertex(vert_i, vertex);
                md.addUV(vert_i, uv);

                if (x < SIZE - 1 && z < SIZE - 1) {
                    triangle_i = md.createTrianglesAt(triangle_i, vert_i);
                }

                vert_i++;
            }
        }
        md.calculateNormals();
        meshes[level] = md;
    }

    void NativeChunk::_init() {
        if (scaleFactor == 0) {
            NativeChunk::scaleFactor = 1;
        }
        meshes.resize(LOD_COUNT);
        meshInstance = ChunkMeshInstance::_new();
        meshInstance->set_name("MeshManager");
        add_child(meshInstance);
    }

    int NativeChunk::currentLOD() const {
        return LOD;
    }

}
