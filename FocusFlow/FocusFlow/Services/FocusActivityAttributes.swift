//
//  FocusActivityAttributes.swift
//  FocusFlow
//
//  Live Activity attributes for Focus sessions.
//  This file must be shared between the main app and widget extension.
//

import Foundation
import ActivityKit

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sessionId: UUID
        var sessionType: String  // "Focus" or "Break"
    }

    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
}
