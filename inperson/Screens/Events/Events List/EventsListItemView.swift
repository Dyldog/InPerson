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
                Text(event.date)
                    .font(.footnote)
                Text(event.responses)
                    .font(.footnote)
            }
            
            Spacer()
            
            Text(event.source).font(.footnote).multilineTextAlignment(.trailing)
        }
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
