import Foundation
import Observation

enum Step: Hashable {
    case selected
    case format
    case quality
    case options
    case processing
    case done
}

@Observable
final class ReconRouter {
    var path: [Step] = []
}
