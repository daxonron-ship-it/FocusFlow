//
//  ContentView.swift
//  FocusFlow
//
//  Created by Rabindra Yadav on 11/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TimerView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
}
