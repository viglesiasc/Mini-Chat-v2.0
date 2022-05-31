//
//  Queue.swift
//  
//
//  Created by Pedro Cuenca on 14/12/21.
//

public enum CollectionsError : Error {
    case maxCapacityReached
}

/// A simple generic Queue protocol with a maximum capacity.
public protocol Queue {
    associatedtype Element
    
    var count: Int { get }
    //var maxCapacity: Int { get }

    mutating func enqueue(_ value: Element) throws
    mutating func dequeue() -> Element?
    
    func forEach(_ body: (Element) throws -> Void) rethrows 
    
    //func contains(where predicate: (Element) -> Bool) -> Bool
    //func findFirst(where predicate: (Element) -> Bool) -> Element?
    
    //mutating func remove(where predicate: (Element) -> Bool)
}

