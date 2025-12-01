//
//  ContentView.swift
//  FocusFlow
//
//  Created by Rabindra Yadav on 11/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .focus

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
    }
}

// MARK: - Schedule List View (Placeholder for Milestone 7)

struct ScheduleListView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.textSecondary)

                Text("Coming Soon")
                    .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Schedule recurring focus sessions to build consistent habits.")
                    .font(.system(size: AppFontSize.body, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("Schedules")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
}
