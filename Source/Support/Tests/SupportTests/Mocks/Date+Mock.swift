//
//  Date+Mock.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

extension Date {

    static func mock(day: UInt = 1, month: UInt = 5, year: UInt = 2_020, hour: UInt = 3, minute: UInt = 36, second: UInt = 12) -> Date {
        var calendar: Calendar = .init(identifier: .gregorian)
        let component: DateComponents = .init(
            calendar: calendar,
            year: Int(year),
            month: Int(month),
            day: Int(day),
            hour: Int(hour),
            minute: Int(minute),
            second: Int(second)
        )

        calendar.locale = .australia
        return calendar.date(from: component)!
    }
}
