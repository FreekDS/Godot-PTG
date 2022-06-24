#ifndef CMAKELIBRARYTEST_NATIVECHUNK_HPP
#define CMAKELIBRARYTEST_NATIVECHUNK_HPP

#include <Godot.hpp>
#include <Curve.hpp>
#include <MeshInstance.hpp>
#include <OpenSimplexNoise.hpp>
#include <Spatial.hpp>
#include <ResourceLoader.hpp>
#include <Material.hpp>
#include <ResourceSaver.hpp>

#include "MeshData.hpp"
#include "ChunkMeshInstance.hpp"

namespace godot {

    class NativeChunk : public Spatial {
    GODOT_CLASS(NativeChunk, Spatial)

        const int SIZE = 241;
        const unsigned LOD_COUNT = 6;

        float scaleFactor;
        float x = 0.0;
        float z = 0.0;
        unsigned LOD = 0;

        Ref<Resource> heightGenerator = nullptr;
        Ref<Material> terrainMaterial = nullptr;

        ChunkMeshInstance *meshInstance = nullptr;

        std::vector<MeshData> meshes;

        void generateLOD(int level);


    public:
        // GODOT REQUIRED METHODS
        void _init();

        static void _register_methods() {
            register_method("generate", &NativeChunk::generate);
            register_method("initialize", &NativeChunk::initialize);
            register_method("set_material", &NativeChunk::setMaterial);
            register_method("get_size", &NativeChunk::getSize);
            register_method("get_scaled_size", &NativeChunk::getScaledSize);
            register_method("switch_lod", &NativeChunk::switchLOD);
            register_method("current_lod", &NativeChunk::currentLOD);

            // Sanity check method
            register_method("hello", &NativeChunk::hello);
        }

        // Custom functions

        void
        initialize(float x, float z, Ref<Resource> heightGenerator = nullptr, unsigned int LOD = 0, float scale = 1);

        void generate();

        void switchLOD(unsigned level, bool bypass = false);

        void setMaterial(Ref<Material> material);

        int getSize();

        float getScaledSize();

        NativeChunk() = default;

        ~NativeChunk() = default;

        void hello();

        int currentLOD() const;

    };

}


#endif //CMAKELIBRARYTEST_NATIVECHUNK_HPP
