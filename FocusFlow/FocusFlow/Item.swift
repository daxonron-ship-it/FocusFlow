//
//  Item.swift
//  FocusFlow
//
//  Created by Rabindra Yadav on 11/30/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
