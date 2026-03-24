import Foundation
import StoreKit
import UIKit

final class RatingService {
    static let shared = RatingService()

    private let defaults = UserDefaults.standard

    // Keys
    private let kLaunchCount        = "rating_launchCount"
    private let kLastPromptDate     = "rating_lastPromptDate"
    private let kHasRated           = "rating_hasRated"
    private let kSessionActions     = "rating_sessionActions"
    private let kTotalPrompts       = "rating_totalPrompts"
    private let kLastBackgroundDate = "rating_lastBackgroundDate"

    // Thresholds
    private let launchesBeforeFirst  = 2          // show on 3rd launch (0-indexed)
    private let cooldownDays         = 3          // min days between prompts
    private let backgroundCooldownHours = 4       // min hours between background prompts
    private let maxPromptsTotal      = 20         // lifetime cap

    private init() {}

    // MARK: - App Launch

    func recordLaunch() {
        defaults.set(launchCount + 1, forKey: kLaunchCount)
    }

    // MARK: - Action tracking (prints, file picks, etc.)

    func recordAction() {
        defaults.set(sessionActions + 1, forKey: kSessionActions)
    }

    // MARK: - Should Show

    /// Check if we should show the emoji rating prompt on app open
    func shouldShowOnLaunch() -> Bool {
        guard canShowPrompt() else { return false }
        return launchCount > launchesBeforeFirst
    }

    /// Check if we should show the rating prompt when app goes to background
    func shouldShowOnBackground() -> Bool {
        guard canShowPrompt() else { return false }
        // Only show on background if user has done at least 1 action this session
        guard sessionActions > 0 else { return false }
        // Separate cooldown for background prompts
        if let lastBg = defaults.object(forKey: kLastBackgroundDate) as? Date {
            let hours = Date().timeIntervalSince(lastBg) / 3600
            guard hours >= Double(backgroundCooldownHours) else { return false }
        }
        return true
    }

    // MARK: - Record prompt shown

    func recordPromptShown(isBackground: Bool = false) {
        defaults.set(Date(), forKey: kLastPromptDate)
        defaults.set(totalPrompts + 1, forKey: kTotalPrompts)
        defaults.set(0, forKey: kSessionActions) // reset session actions
        if isBackground {
            defaults.set(Date(), forKey: kLastBackgroundDate)
        }
    }

    // MARK: - Handle Rating Response

    func handlePositiveRating() {
        defaults.set(true, forKey: kHasRated)
        requestStoreReview()
    }

    func handleNeutralRating() {
        // Just dismiss, will ask again after cooldown
    }

    func handleNegativeRating() {
        // Don't ask again for a longer period — cooldown handles it
    }

    // MARK: - Store Review

    private func requestStoreReview() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    // MARK: - Helpers

    private var launchCount: Int { defaults.integer(forKey: kLaunchCount) }
    private var sessionActions: Int { defaults.integer(forKey: kSessionActions) }
    private var totalPrompts: Int { defaults.integer(forKey: kTotalPrompts) }
    private var hasRated: Bool { defaults.bool(forKey: kHasRated) }

    private func canShowPrompt() -> Bool {
        // Lifetime cap
        guard totalPrompts < maxPromptsTotal else { return false }
        // Cooldown check
        if let lastDate = defaults.object(forKey: kLastPromptDate) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSince >= cooldownDays else { return false }
        }
        return true
    }
}
