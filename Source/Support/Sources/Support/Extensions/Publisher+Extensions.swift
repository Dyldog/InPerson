//
//  Publisher+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Combine
import Foundation

public extension Publisher where Failure == Never {
    func sinkMain(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        receive(on: RunLoop.main).sink(receiveValue: receiveValue)
    }
}

public extension Publisher {

    func ignoringOutcome() -> AnyPublisher<Void, Never> {
        map { _ in () }.replaceError(with: ()).eraseToAnyPublisher()
    }

    /// Runs the publisher in the background using the given cancellables
    /// - Parameter cancellables: Cancellables array to store publisher
    func sinkIgnoringAll(in cancellables: inout Set<AnyCancellable>) {
        ignoringOutcome()
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func retry<S: Scheduler>(
        _ max: Int = Int.max,
        delay: Publishers.RetryDelay<Self, S>.TimingFunction,
        scheduler: S
    ) -> Publishers.RetryDelay<Self, S> {
        .init(upstream: self, max: max, delay: delay, scheduler: scheduler)
    }
}

public extension Publishers {

    struct RetryDelay<Upstream: Publisher, S: Scheduler>: Publisher {

        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        public let upstream: Upstream

        public let retries: Int
        public let max: Int
        public let delay: TimingFunction
        public let scheduler: S

        public init(upstream: Upstream, retries: Int = 0, max: Int, delay: TimingFunction, scheduler: S) {
            self.upstream = upstream
            self.retries = retries
            self.max = max
            self.delay = delay
            self.scheduler = scheduler
        }

        public func receive<S: Subscriber>(subscriber: S) where Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.catch { e -> AnyPublisher<Output, Failure> in
                guard retries < max else { return Fail(error: e).eraseToAnyPublisher() }
                return Fail(error: e)
                    .delay(for: .seconds(delay(retries + 1)), scheduler: scheduler)
                    .print()
                    .catch { _ in
                        RetryDelay(
                            upstream: upstream,
                            retries: retries + 1,
                            max: max,
                            delay: delay,
                            scheduler: scheduler
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .print()
            .subscribe(subscriber)
        }
    }
}

public extension Publishers.RetryDelay {
    typealias TimingFunction = RetryDelayTimingFunction
}

public struct RetryDelayTimingFunction {

    let function: (Int) -> TimeInterval

    public init(_ function: @escaping (Int) -> TimeInterval) {
        self.function = function
    }

    public func callAsFunction(_ n: Int) -> TimeInterval {
        function(n)
    }
}

public extension Publishers.RetryDelay.TimingFunction {
    static let immediate: Self = .after(seconds: 0)
    static func after(seconds time: TimeInterval) -> Self { .init(time) }
    static func exponential(unit: TimeInterval = 0.5) -> Self {
        .init { n in
            TimeInterval.random(in: unit ... unit * pow(2, TimeInterval(n - 1)))
        }
    }
}

extension Publishers.RetryDelay.TimingFunction: ExpressibleByFloatLiteral {

    public init(_ value: TimeInterval) {
        self.init { _ in value }
    }

    public init(floatLiteral value: TimeInterval) {
        self.init(value)
    }
}
