//
//  ContentView.swift
//  FocusFlow
//
//  Created by Rabindra Yadav on 11/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Tab = .focus
    @StateObject private var scheduleManager = ScheduleManager.shared

    enum Tab {
        case focus
        case stats
        case schedules
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem {
                    Label("Focus", systemImage: "target")
                }
                .tag(Tab.focus)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(Tab.stats)

            ScheduleListView()
                .tabItem {
                    Label("Schedules", systemImage: "calendar")
                }
                .tag(Tab.schedules)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.accent)
        .onAppear {
            scheduleManager.setModelContext(modelContext)
            scheduleManager.checkAndActivateSchedules()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                scheduleManager.checkAndActivateSchedules()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self, Schedule.self], inMemory: true)
}
