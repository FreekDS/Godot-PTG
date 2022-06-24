#ifndef CMAKELIBRARYTEST_CHUNKMESHINSTANCE_HPP
#define CMAKELIBRARYTEST_CHUNKMESHINSTANCE_HPP

#include <MeshInstance.hpp>
#include <CollisionShape.hpp>
#include <Godot.hpp>
#include <RID.hpp>
#include <PhysicsServer.hpp>
#include <VisualServer.hpp>

#include <vector>

#include "MeshData.hpp"


namespace godot {

    class ChunkMeshInstance : public Node {
    GODOT_CLASS(ChunkMeshInstance, Node)

    private:
        bool hasCollider(int LOD);
        void createCollision(int LOD);

        static String LODtoStr(int LOD);

        VisualServer* renderServer = nullptr;
        PhysicsServer* physicsServer = nullptr;

        std::vector<RID> meshRIDs;
        std::vector<RID> colliderRIDs;

    public:

        void _init() {
            renderServer = VisualServer::get_singleton();
            physicsServer = PhysicsServer::get_singleton();
        }

        static void _register_methods() {}

        void createRIDs(std::vector<MeshData>* meshes, RID worldScenario, RID worldSpace);

        void switchCollider(int LOD);

        ~ChunkMeshInstance();

    };

}


#endif //CMAKELIBRARYTEST_CHUNKMESHINSTANCE_HPP
