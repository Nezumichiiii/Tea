//
//  ContentView.swift
//  Tea
//
//  Created by Matyáš  Šebek on 28.10.2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var isKeepingAwake = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "cup.and.saucer")
                .resizable()
                .imageScale(.large)
                .frame(width: 80, height: 80)
                .foregroundStyle(.tint)
            Toggle(isOn: $isKeepingAwake) {
                Text("Keep Awake")
                    .font(.title2)
                    .bold()
            }
            .toggleStyle(.switch)
            Text(isKeepingAwake ? "Tea is keeping you awake!" : "The device can sleep.")
                .font(.headline)
        }
        .padding()
        .onChange(of: isKeepingAwake) { _, newValue in
#if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = newValue
#endif
        }
    }
}

#Preview {
    ContentView()
}
