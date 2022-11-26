//
//  EventResponsePicker.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

struct EventResponsePicker: View {
    @Binding var selection: Attendance?

    var body: some View {
        Picker("Going", selection: $selection) {
            Text("No Response").tag(nil as Attendance?)
            ForEach([Attendance.going, .maybe, .notGoing]) {
                Text("\($0.emoji) \($0.title)").tag($0 as Attendance?)
            }
        }
//        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}
