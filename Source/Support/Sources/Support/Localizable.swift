//
//  Localizable.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

private enum LocalizableType: String {
    case title
    case titleAccessibilityLabel = "title.accessibilityLabel"
    case titleAccessibilityHint = "title.accessibilityHint"

    case textAccessibilityLabel = "accessibilityLabel"
    case textAccessibilityHint = "accessibilityHint"

    case link

    case confirmAction
    case confirmActionAccessibilityLabel = "confirmAction.accessibilityLabel"
    case confirmActionAccessibilityHint = "confirmAction.accessibilityHint"
    case confirmActionLink = "confirmAction.link"

    case cancelAction
    case cancelActionAccessibilityLabel = "cancelAction.accessibilityLabel"
    case cancelActionAccessibilityHint = "cancelAction.accessibilityHint"
}

public protocol Localizable: RawRepresentable {

    var title: String { get }
    var titleAccessibilityLabel: String? { get }
    var titleAccessibilityHint: String? { get }

    var text: String { get }
    var textAccessibilityLabel: String? { get }
    var textAccessibilityHint: String? { get }

    var link: String { get }

    var confirmAction: String { get }
    var confirmActionAccessibilityLabel: String? { get }
    var confirmActionAccessibilityHint: String? { get }
    var confirmActionLink: String { get }

    var cancelAction: String { get }
    var cancelActionAccessibilityLabel: String? { get }
    var cancelActionAccessibilityHint: String? { get }

    /// Lookup the localized string by given key
    ///
    /// - Parameter key: strings file key
    /// - Returns: localized string
    func localize(key: String, default: String?) -> String
}

// Default implementation for String representable types.
// Uses the String value as the key.
public extension Localizable where RawValue == String {

    var title: String { title() }
    var titleAccessibilityLabel: String? { titleAccessibilityLabel() }
    var titleAccessibilityHint: String? { titleAccessibilityHint() }

    var text: String { text() }
    var textAccessibilityLabel: String? { textAccessibilityLabel() }
    var textAccessibilityHint: String? { textAccessibilityHint() }

    var link: String { textLink() }

    var confirmAction: String { confirmAction() }
    var confirmActionAccessibilityLabel: String? { confirmActionAccessibilityLabel() }
    var confirmActionAccessibilityHint: String? { confirmActionAccessibilityHint() }
    var confirmActionLink: String { confirmActionLink() }

    var cancelAction: String { cancelAction() }
    var cancelActionAccessibilityLabel: String? { cancelActionAccessibilityLabel() }
    var cancelActionAccessibilityHint: String? { cancelActionAccessibilityHint() }

    func title(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(with: LocalizableType.title.rawValue, arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func titleAccessibilityLabel(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.titleAccessibilityLabel.rawValue, arguments: arguments)
    }

    func titleAccessibilityHint(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.titleAccessibilityHint.rawValue, arguments: arguments)
    }

    func title(_ argument: CVarArg) -> String {
        return title([argument])
    }

    func titleAccessibilityLabel(_ argument: CVarArg) -> String? {
        return titleAccessibilityLabel([argument])
    }

    func titleAccessibilityHint(_ argument: CVarArg) -> String? {
        return titleAccessibilityHint([argument])
    }

    func text(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func textAccessibilityLabel(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.textAccessibilityLabel.rawValue, arguments: arguments)
    }

    func textAccessibilityHint(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.textAccessibilityHint.rawValue, arguments: arguments)
    }

    func textLink(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(with: LocalizableType.link.rawValue, arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func text(_ argument: CVarArg) -> String {
        return text([argument])
    }

    func textAccessibilityLabel(_ argument: CVarArg) -> String? {
        return textAccessibilityLabel([argument])
    }

    func textAccessibilityHint(_ argument: CVarArg) -> String? {
        return textAccessibilityHint([argument])
    }

    func textLink(_ argument: CVarArg) -> String {
        return textLink([argument])
    }

    func confirmAction(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(with: LocalizableType.confirmAction.rawValue, arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func confirmActionAccessibilityLabel(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.confirmActionAccessibilityLabel.rawValue, arguments: arguments)
    }

    func confirmActionAccessibilityHint(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.confirmActionAccessibilityHint.rawValue, arguments: arguments)
    }

    func confirmActionLink(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(with: LocalizableType.confirmActionLink.rawValue, arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func confirmAction(_ argument: CVarArg) -> String {
        return confirmAction([argument])
    }

    func confirmActionAccessibilityLabel(_ argument: CVarArg) -> String? {
        return confirmActionAccessibilityLabel([argument])
    }

    func confirmActionAccessibilityHint(_ argument: CVarArg) -> String? {
        return confirmActionAccessibilityHint([argument])
    }

    func confirmActionLink(_ argument: CVarArg) -> String {
        return confirmActionLink([argument])
    }

    func cancelAction(_ arguments: [CVarArg] = []) -> String {
        guard let value = localize(with: LocalizableType.cancelAction.rawValue, arguments: arguments) else {
            fatalError("Unknown localizable text type with arguments ")
        }
        return value
    }

    func cancelActionAccessibilityLabel(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.cancelActionAccessibilityLabel.rawValue, arguments: arguments)
    }

    func cancelActionAccessibilityHint(_ arguments: [CVarArg] = []) -> String? {
        return localize(with: LocalizableType.cancelActionAccessibilityHint.rawValue, arguments: arguments)
    }

    func cancelAction(_ argument: CVarArg) -> String {
        return cancelAction([argument])
    }

    func cancelActionAccessibilityLabel(_ argument: CVarArg) -> String? {
        return cancelActionAccessibilityLabel([argument])
    }

    func cancelActionAccessibilityHint(_ argument: CVarArg) -> String? {
        return cancelActionAccessibilityHint([argument])
    }

    private func localize(with suffix: String? = nil, arguments: [CVarArg]) -> String? {
        let notFoundValue = "??????????????"
        let key: String
        if let suffix = suffix {
            key = rawValue.appending(".".appending(suffix))
        } else {
            key = rawValue
        }

        // find localised string using funky default, so we can test for not found
        let localizeString = localize(key: key, default: notFoundValue)

        if localizeString == notFoundValue { return nil }

        if arguments.isEmpty {
            return localizeString
        }

        return String(format: localizeString, arguments: arguments)
    }
}
