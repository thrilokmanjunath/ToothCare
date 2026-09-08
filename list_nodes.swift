import Foundation
import SceneKit

let url = URL(fileURLWithPath: "Teeth.usdz")
guard let scene = try? SCNScene(url: url, options: nil) else {
    print("Could not load scene")
    exit(1)
}

func printNodes(node: SCNNode, depth: Int = 0) {
    if let name = node.name {
        print(String(repeating: "  ", count: depth) + "- \(name)")
    } else {
        print(String(repeating: "  ", count: depth) + "- (unnamed)")
    }
    for child in node.childNodes {
        printNodes(node: child, depth: depth + 1)
    }
}

printNodes(node: scene.rootNode)
