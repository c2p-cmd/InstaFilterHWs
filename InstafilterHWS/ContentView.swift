//
//  ContentView.swift
//  InstafilterHWS
//
//  Created by Sharan Thakur on 25/12/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("nav_title") private var navTitle = "Processing Lab 🔬"
    
    var body: some View {
        NavigationStack {
            EditingView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle($navTitle)
        }
    }
}

#Preview {
    ContentView()
}
