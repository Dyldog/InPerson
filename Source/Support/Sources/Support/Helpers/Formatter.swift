//
//  Formatter.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public enum Formatter {}

// MARK: - Date

public extension Formatter {

    enum Date {

        public static func dayMonth(_ date: Foundation.Date) -> String {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "E, d MMM"
            dateFormatter.locale = .australia
            return dateFormatter.string(from: date)
        }

        public static func time(_ date: Foundation.Date) -> String {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "h:mm a"
            dateFormatter.locale = .australia
            return dateFormatter.string(from: date)
        }

        /// a function to return a date in string in the format "dd MM yyyy"
        /// - parameters:
        ///   - date: the date to be converted
        /// - Example: *25 Dec 2022*
        public static func dayMonthYear(_ date: Foundation.Date) -> String {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "dd MMM yyyy"
            dateFormatter.locale = .australia
            return dateFormatter.string(from: date)
        }

        /// a function to return a date in string in the format "MMM yyyy"
        /// - parameters:
        ///   - date: the date to be converted
        /// - Example: *Dec 2022*
        public static func monthYear(_ date: Foundation.Date) -> String {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "MMM yyyy"
            dateFormatter.locale = .australia
            return dateFormatter.string(from: date)
        }

        /// a function to return a date in string in the format "MMM yyyy"
        /// - parameters:
        ///   - date: the date to be converted
        /// - Example: *December 2022*
        public static func fullMonthYear(_ date: Foundation.Date) -> String {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "MMMM yyyy"
            dateFormatter.locale = .australia
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - Monetary

public extension Formatter {

    enum Monetary {

        /// a function that returns a string with "$" symbol
        /// also, this function rounds the decimal places to two
        /// - parameters:
        ///   - amount: the amount to be converted
        /// - Example: providing the value 102.6471 to the function yields *$102.65*
        public static func twoDecimalPlaces(_ amount: Decimal, showPlusPrefix: Bool = false) -> String {
            let numberFormatter: NumberFormatter = .init()
            numberFormatter.locale = .australia
            numberFormatter.numberStyle = .currency
            numberFormatter.roundingMode = .halfUp

            if showPlusPrefix {
                numberFormatter.positivePrefix = numberFormatter.plusSign + numberFormatter.currencySymbol
            }

            return numberFormatter.string(from: amount as NSDecimalNumber)!
        }

        public static func noDecimalPlaces(_ amount: Decimal) -> String {
            let numberFormatter: NumberFormatter = .init()
            numberFormatter.locale = .australia
            numberFormatter.numberStyle = .currency
            numberFormatter.maximumFractionDigits = 0
            numberFormatter.roundingMode = .down

            return numberFormatter.string(from: amount as NSDecimalNumber)!
        }
    }
}

// MARK: - Number

public extension Formatter {

    enum Number {

        /// Function convert a float to string with two decimal points.
        /// - Parameter amount: the float amount to be converted
        /// - Returns: Example: providing the value 102.6471 to the function yields *102.64%*
        public static func percentage(_ amount: Double) -> String {
            let numberFormatter: NumberFormatter = .init()
            numberFormatter.maximumFractionDigits = 2
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.roundingMode = .down
            return numberFormatter.string(from: NSNumber(value: amount))! + "%"
        }
    }
}
