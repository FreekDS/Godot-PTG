#ifndef CMAKELIBRARYTEST_UTILS_H
#define CMAKELIBRARYTEST_UTILS_H

#include <PoolArrays.hpp>
#include <vector>

namespace godot {

    template<typename P_VEC, typename T>
    inline P_VEC toPool(std::vector<T> &vector) {
        P_VEC poolVec{};
        for (const auto &v: vector) {
            poolVec.append(v);
        }
        return poolVec;
    }

    inline PoolVector2Array toPoolVector2(std::vector<Vector2> &vec) {
        return toPool<PoolVector2Array, Vector2>(vec);
    }

    inline PoolIntArray toPoolInt(std::vector<int> vec) {
        return toPool<PoolIntArray, int>(vec);
    }

    inline PoolVector3Array toPoolVector3(std::vector<Vector3> &vec) {
        return toPool<PoolVector3Array, Vector3>(vec);
    }

}

#endif //CMAKELIBRARYTEST_UTILS_H
