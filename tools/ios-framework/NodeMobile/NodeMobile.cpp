
#import "NodeMobile.h"

namespace node {
    int Start(int argc, char *argv[]);
    void Stop();
} // namespace node

int node_start(int argc, char *argv[]) {
    return node::Start(argc, argv);
}

void node_stop() {
    node::Stop();
}
