import Foundation
import SwiftUI

class RatingService: ObservableObject {
    static let shared = RatingService()

    @AppStorage("userRatingPoints") var points: Int = 0
    @AppStorage("userRatingTier") var tierRaw: Int = 1

    static let tier2Threshold = 5000

    var tier: Int {
        get { tierRaw }
        set { tierRaw = newValue }
    }

    var isTier2: Bool {
        tier >= 2
    }

    var progressToTier2: Double {
        if isTier2 { return 1.0 }
        return min(Double(points) / Double(Self.tier2Threshold), 1.0)
    }

    var pointsToNextTier: Int {
        if isTier2 { return 0 }
        return max(Self.tier2Threshold - points, 0)
    }

    private init() {
        recalculateTier()
    }

    func addPoints(_ count: Int = 1) {
        points += count
        recalculateTier()
    }

    func recalculateTier() {
        if points >= Self.tier2Threshold {
            tier = 2
        } else {
            tier = 1
        }
    }

    func resetRating() {
        points = 0
        tier = 1
    }
}
