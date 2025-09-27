// In ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        
        // This check will fail for ALL users today,
        // because iOS 26.0 does not exist yet.
        if #available(iOS 26.0, *) {
        
            // NO ONE will see this TabView.
            TabView {
                            // MARK: - Home Tab
                HomeView() // <-- Use the new view here
                    .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

                SupplementsView()
                    .tabItem { Label("Supplements", systemImage: "pills.fill") }

                // MARK: - Insights Tab
                InsightsView() // <-- Use the new view here
                    .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }

                // MARK: - Settings Tab
                SettingsView() // <-- Use the new view here
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .tint(.blue)
            
        } else {
            // EVERY user will see this message instead of your app.
            Text("This app is not compatible with your device's iOS version.")
                .padding()
        }
    }
}


