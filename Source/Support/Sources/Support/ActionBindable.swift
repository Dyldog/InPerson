//
//  ActionBindable.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation

public protocol ActionBindable {}

public extension ActionBindable {

    func binding<T: Publisher>(
        to actionKeyPath: KeyPath<Self, T>,
        in cancellables: inout Set<AnyCancellable>,
        _ action: @escaping Block
    ) -> Self where T.Output == Void?, T.Failure == Never {
        self[keyPath: actionKeyPath]
            .dropFirst()
            .sink(receiveValue: { _ in action() })
            .store(in: &cancellables)

        return self
    }

    @discardableResult
    func mapping<T: Publisher>(
        _ keyPath: KeyPath<Self, T>,
        in cancellables: inout Set<AnyCancellable>,
        _ action: @escaping TaskIn<T.Output>
    ) -> Self where T.Failure == Never {
        self[keyPath: keyPath]
            .receive(on: RunLoop.main)
            .sink(receiveValue: { action($0) })
            .store(in: &cancellables)

        return self
    }
}
