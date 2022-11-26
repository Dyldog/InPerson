//
//  FormatterTests.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

@testable import enum Support.Formatter
import XCTest

final class FormatterTests: XCTestCase {

    // MARK: - Lifecycle

    func testDayMonthYear() {
        let data: [(Date, String)] = [
            (.mock(day: 1, month: 1, year: 2_012), "01 Jan 2012"),
            (.mock(day: 2, month: 2, year: 2_013), "02 Feb 2013"),
            (.mock(day: 3, month: 3, year: 2_014), "03 Mar 2014"),
            (.mock(day: 4, month: 4, year: 2_015), "04 Apr 2015"),
            (.mock(day: 5, month: 5, year: 2_016), "05 May 2016"),
            (.mock(day: 6, month: 6, year: 2_017), "06 Jun 2017"),
            (.mock(day: 7, month: 7, year: 2_018), "07 Jul 2018"),
            (.mock(day: 8, month: 8, year: 2_019), "08 Aug 2019"),
            (.mock(day: 9, month: 9, year: 2_020), "09 Sep 2020"),
            (.mock(day: 10, month: 10, year: 2_021), "10 Oct 2021"),
            (.mock(day: 11, month: 11, year: 1_990), "11 Nov 1990"),
            (.mock(day: 12, month: 12, year: 1_991), "12 Dec 1991"),
        ]

        data.forEach {
            XCTAssertEqual(Formatter.Date.dayMonthYear($0.0), $0.1)
        }
    }

    func testMonthYear() {
        let data: [(Date, String)] = [
            (.mock(day: 1, month: 1, year: 2_012), "Jan 2012"),
            (.mock(day: 2, month: 2, year: 2_013), "Feb 2013"),
            (.mock(day: 3, month: 3, year: 2_014), "Mar 2014"),
            (.mock(day: 4, month: 4, year: 2_015), "Apr 2015"),
            (.mock(day: 5, month: 5, year: 2_016), "May 2016"),
            (.mock(day: 6, month: 6, year: 2_017), "Jun 2017"),
            (.mock(day: 7, month: 7, year: 2_018), "Jul 2018"),
            (.mock(day: 8, month: 8, year: 2_019), "Aug 2019"),
            (.mock(day: 9, month: 9, year: 2_020), "Sep 2020"),
            (.mock(day: 10, month: 10, year: 2_021), "Oct 2021"),
            (.mock(day: 11, month: 11, year: 1_990), "Nov 1990"),
            (.mock(day: 12, month: 12, year: 1_991), "Dec 1991"),
        ]

        data.forEach {
            XCTAssertEqual(Formatter.Date.monthYear($0.0), $0.1)
        }
    }

    func testDollarCurrencyTwoDigitRoundedDecimal() {
        let data: [(Decimal, String)] = [
            (0, "$0.00"),
            (0.89, "$0.89"),
            (1, "$1.00"),
            (2.58, "$2.58"),
            (3.959723779, "$3.96"),
            (3.958723779, "$3.96"),
            (3.957723779, "$3.96"),
            (3.956723779, "$3.96"),
            (3.955723779, "$3.96"),
            (5.1, "$5.10"),
            (100, "$100.00"),
            (1_000, "$1,000.00"),
            (10_000, "$10,000.00"),
            (100_000, "$100,000.00"),
            (1_000_000, "$1,000,000.00"),
            (1_000_000.81, "$1,000,000.81"),
            (-0.89, "-$0.89"),
            (-1, "-$1.00"),
            (-2.58, "-$2.58"),
            (-3.959723779, "-$3.96"),
            (-5.1, "-$5.10"),
            (-100, "-$100.00"),
            (-1_000, "-$1,000.00"),
            (-10_000, "-$10,000.00"),
            (-100_000, "-$100,000.00"),
            (-1_000_000, "-$1,000,000.00"),
            (-10_000_000.81, "-$10,000,000.81"),
            (-100_000_000.81, "-$100,000,000.81"),
            (-1_000_000_000.81, "-$1,000,000,000.81"),
        ]

        data.forEach {
            XCTAssertEqual(Formatter.Monetary.twoDecimalPlaces($0.0), $0.1)
        }

        let positiveAmountData: [(Decimal, String)] = [
            (10_000, "+$10,000.00"),
            (300.96, "+$300.96"),
            (12_000.956723779, "+$12,000.96"),
            (-1_000.08, "-$1,000.08"),
            (0, "+$0.00"),
        ]

        positiveAmountData.forEach {
            XCTAssertEqual(Formatter.Monetary.twoDecimalPlaces($0.0, showPlusPrefix: true), $0.1)
        }
    }

    func testNoDecimalPlaces() {
        let data: [(Decimal, String)] = [
            (0, "$0"),
            (0.89, "$0"),
            (2.55, "$2"),
            (3.959723779, "$3"),
            (3.958723779, "$3"),
            (3.957723779, "$3"),
            (3.956723779, "$3"),
            (3.955723779, "$3"),
            (100, "$100"),
            (1_000, "$1,000"),
            (10_000, "$10,000"),
            (100_000, "$100,000"),
            (1_000_000, "$1,000,000"),
            (1_000_000.81, "$1,000,000"),
            (-0.89, "-$0"),
            (-1, "-$1"),
            (-3.959723779, "-$3"),
            (-100, "-$100"),
            (-1_000, "-$1,000"),
            (-10_000, "-$10,000"),
            (-100_000, "-$100,000"),
            (-1_000_000, "-$1,000,000"),
            (-10_000_000.81, "-$10,000,000"),
            (-100_000_000.81, "-$100,000,000"),
            (-1_000_000_000.81, "-$1,000,000,000"),
        ]

        data.forEach {
            XCTAssertEqual(Formatter.Monetary.noDecimalPlaces($0.0), $0.1)
        }
    }

    func testFloatValueToTwoDecimalPlaces() {
        let data: [(Double, String)] = [
            (0.00, "0.00%"),
            (0.8901, "0.89%"),
            (5.1245667, "5.12%"),
            (5.1265667, "5.12%"),
            (5.101, "5.10%"),
            (5.1, "5.10%"),
            (5.5, "5.50%"),
            (1, "1.00%"),
            (10, "10.00%"),
            (100, "100.00%"),
            (-10, "-10.00%"),
            (-0.8901, "-0.89%"),
            (-5.1245667, "-5.12%"),
            (-5.1265667, "-5.12%"),
            (-100, "-100.00%"),
        ]

        data.forEach {
            XCTAssertEqual(Formatter.Number.percentage(Double($0.0)), $0.1)
        }
    }
}
