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

struct ResponderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResponderView(name: "NAME", response: .host)
                .previewLayout(.sizeThatFits)
            
            ResponderView(name: "NAME", response: .notResponded)
                .previewLayout(.sizeThatFits)
            
            ResponderView(name: "NAME", response: .attendance(.going))
                .previewLayout(.sizeThatFits)
            
            ResponderView(name: "NAME", response: .invited)
                .previewLayout(.sizeThatFits)
        }
    }
}
