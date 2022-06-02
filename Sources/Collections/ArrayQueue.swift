public struct ArrayQueue<Element> : Queue {
    private var storage = [Element]()

    public var count : Int {return storage.count}

    public var maxCapacity: Int 
    
    public mutating func enqueue(_ value: Element) {
        // Your code here
        storage.append(value)
    }
    
    public mutating func dequeue() -> Element? {
        return storage.remove(at: 0)
    }
    
    //public func contains(_ value: Element) -> Bool {
    //    return storage.contains(value)
    //}

    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage.forEach {try body($0)}
    }
    

    public init (maxCapacity: Int){
        self.maxCapacity = maxCapacity
    }

    public mutating func remove(where predicate: (Element) -> Bool) {
        storage.removeAll(where: predicate)
    }

}
