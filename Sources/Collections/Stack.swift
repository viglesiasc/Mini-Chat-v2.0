//
//  Stack.swift
//  
//
//  Created by Pedro Cuenca on 14/12/21.
//

/// A simple generic Stack protocol.
public protocol Stack {
    associatedtype Element
    
    mutating func push(_ value: Element)
    mutating func pop() -> Element?
    
    func forEach(_ body: (Element) throws -> Void) rethrows
}
