//
//  FocusActivityAttributes.swift
//  FocusFlowWidgetExtension
//
//  Live Activity attributes for Focus sessions.
//  NOTE: This is a duplicate of the file in the main app.
//  Both targets need access to this struct.
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
