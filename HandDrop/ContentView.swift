//
//  ContentView.swift
//  HandDrop
//
//  Created by Angel Adrian Pimienta Flores on 10/12/24.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var text: String = ""

    var body: some View {
        VStack {
            TextField("Text", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Copy") {
                UIPasteboard.general.string = text
            }
        }
    }
}

#Preview {
    ContentView()
}
