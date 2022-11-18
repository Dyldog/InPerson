//
//  ResponderView.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

struct ResponderView: View {
    let name: String
    let response: ResponseStatus
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            
            Text(response.title)
                .foregroundColor(.white)
                .padding(4)
                .background(response.color)
                .cornerRadius(10)
        }
        .padding()
    }
}
