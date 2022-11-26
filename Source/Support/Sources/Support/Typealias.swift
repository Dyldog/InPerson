//
//  Typealias.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

public typealias Block = () -> Void
public typealias ThrowingBlock = () throws -> Void
public typealias ThrowingInBlock<In> = (In) throws -> Void
public typealias TaskIn<In> = (In) -> Void
public typealias TaskOut<Out> = () -> Out
public typealias Task<In, Out> = (In) -> Out
