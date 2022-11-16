//
//  AddEventView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import SwiftUI

struct AddEventsView: View {
    @State var title: String = ""
    @State var date: Date = .now
    
    let onDone: ((String, Date)) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $title, prompt: Text("Title")).font(.largeTitle)
                    .padding(.top, 20)
                DatePicker("Date", selection: $date).font(.largeTitle)
                Button("Add") {
                    onDone((title, date))
                }
                .font(.largeTitle)
                .padding(.top, 40)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Event")
        }
    }
}
