#include <string>
#include "ChunkMeshInstance.hpp"

namespace godot {

    void ChunkMeshInstance::createCollision(int LOD) {
        Node *newCollision = nullptr;
        Array childeren = get_children();
        for (int i = 0; i < childeren.size(); i++) {
            Node *child = childeren[i];
            if (!child->get_name().is_valid_float()) {
                newCollision = child;
                break;
            }
        }
        if (newCollision != nullptr) {
            newCollision->set_name(LODtoStr(LOD));
        }
    }

    bool ChunkMeshInstance::hasCollider(int LOD) {
        Array childeren = get_children();
        String name = LODtoStr(LOD);
        for (int i = 0; i < childeren.size(); i++) {
            Node *child = childeren[i];
            if (child->get_name() == name) {
                return true;
            }
        }
        return false;
    }

    void ChunkMeshInstance::switchCollider(int LOD) {
        if (!hasCollider(LOD)) {
            createCollision(LOD);
        }

        String name = LODtoStr(LOD);

        Array childeren = get_children();
        for (int i = 0; i < childeren.size(); i++) {
            Spatial *child = childeren[i];

            if (child->get_name() == name) {
                // enable
                child->set_visible(true);
                if (child->get_child_count() > 0) {
                    CollisionShape *shape = static_cast<CollisionShape *>(child->get_child(0));
                    shape->set_deferred("disabled", false);
                }
            } else {
                // disable
                child->set_visible(false);
                if (child->get_child_count() > 0) {
                    CollisionShape *shape = static_cast<CollisionShape *>(child->get_child(0));
                    shape->set_deferred("disabled", true);
                }
            }

        }

    }

    String ChunkMeshInstance::LODtoStr(int LOD) {
        return std::to_string(LOD).c_str();
    }

    void ChunkMeshInstance::createRIDs(std::vector<MeshData> *meshes, RID worldScenario, RID worldSpace) {
        colliderRIDs.resize(meshes->size());
        meshRIDs.resize(meshes->size());
        for (int i = 0; i < meshes->size(); i++) {
            MeshData& md = meshes->at(i);
            Ref<Mesh> mesh = md.buildMesh();
            Ref<Shape> shape = md.getShape();

            meshRIDs[i] = renderServer->instance_create2(
                        mesh->get_rid(), worldScenario
                    );
            renderServer->instance_set_visible(meshRIDs[i], false);

            // Add collider RID, disable it immediately
            colliderRIDs[i] = physicsServer->body_create(PhysicsServer::BODY_MODE_STATIC);
            physicsServer->body_set_space(colliderRIDs[i], worldSpace);
            physicsServer->body_add_shape(colliderRIDs[i], shape->get_rid());
            physicsServer->body_set_shape_disabled(colliderRIDs[i], 0, true);

            // TODO, transform moet nog gezet worden, terrain material ook
        }
    }

    ChunkMeshInstance::~ChunkMeshInstance() {
        // important: cleanup RIDs created on destructor
        for(int i = 0; i<meshRIDs.size(); i++) {
            renderServer->free_rid(meshRIDs[i]);
            physicsServer->free_rid(colliderRIDs[i]);
        }
    }
}
