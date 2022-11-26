//
//  EventsListItemView.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

struct EventListItem: Identifiable {
    var id: String
    let title: String
    let date: String
    let source: String
    let responses: String
}

struct EventListItemView: View {
    let event: EventListItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .bold()
                    .padding(.top, 1.0)
                Text(event.date)
                    .font(.subheadline)
                    .padding(.top, 0.0)
                Text(event.responses)
                    .font(.subheadline)
                    .padding(.top, 1.0)
            }
            .padding(.trailing, 6.0)
            
            Spacer()
            
            Text(event.source).font(.footnote).foregroundColor(Color.gray).multilineTextAlignment(.trailing).padding(.trailing, 5.0)
        }
        .padding(.trailing, 2.0)
    }
}

struct EventListItemView_Preivews: PreviewProvider {
    static var previews: some View {
        EventListItemView(event: .init(
            id: UUID().uuidString,
            title: "TITLE",
            date: "DATE",
            source: "SOURCE",
            responses: "RESPONSES"
        ))
        .previewLayout(.sizeThatFits)
    }
}
