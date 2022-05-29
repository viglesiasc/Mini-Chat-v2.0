import XCTest
@testable import Collections

final class CollectionsTests: XCTestCase {
    var data = [
        (key: "nbc.com", value: "66.77.124.26"),
        (key: "facebook.com", value: "69.63.181.12"),
        (key: "yelp.com", value: "63.251.52.110"),
        (key: "bbva.es", value: "195.76.187.83"),
        (key: "google.com", value: "69.63.189.16"),
        (key: "viacom.com", value: "206.220.43.92"),
        (key: "zappos.com", value: "66.209.92.150"),
        (key: "cbs.com", value: "198.99.118.37"),
        (key: "ucla.edu", value: "169.232.55.22"),
        (key: "xing.com", value: "213.238.60.19"),
        (key: "wings.com", value: "12.155.29.35"),
        (key: "boingboing.net", value: "204.11.50.136"),
        (key: "edi.com", value: "192.86.2.98"),
    ]
    
    typealias Entry = (key: String, value: String)
    
    lazy var sortedData: [(key: String, value: String)] = {
        return data.sorted { return $0.key < $1.key }
    }()
    
    func createQueue(maxCapacity: Int = 50) throws -> ArrayQueue<Entry> {
        var queue = ArrayQueue<Entry>(maxCapacity: maxCapacity)
        for entry in data {
            try queue.enqueue(entry)
        }
        return queue
    }

    func testQueue() {
        var q = try! createQueue()
        XCTAssertEqual(q.count, data.count, "Invalid count: \(q.count), expected: \(data.count)")

        for (key, _) in data {
            XCTAssertEqual(q.dequeue()?.key, key)
        }
        
        XCTAssertEqual(q.count, 0, "Invalid count: \(q.count), should be 0 after dequeuing")
        XCTAssertNil(q.dequeue(), "Dequeue should return nil on empty queue")
    }

    func testIteration() {
        let q = try! createQueue()
        var i = 0
        q.forEach { (key, _) in
            let item = data[i]
            i += 1
            XCTAssertEqual(key, item.key, "Wrong order, got \(key), expected: \(item.key)")
        }
    }

    func testContains() {
        let q = try! createQueue()
        XCTAssertTrue(q.contains { $0.key == data[5].key } )
        XCTAssertFalse(q.contains { $0.key == "This key does not exist" } )
    }
    
    func testRemove() {
        var q = try! createQueue()
        
        q.remove { $0.key == "viacom.com" }
        XCTAssertEqual(q.count, data.count - 1)
    }

    func testMaxCapacity() {
        XCTAssertThrowsError(try createQueue(maxCapacity: 5))
        
        var q = ArrayQueue<Entry>(maxCapacity: 1)
        XCTAssertNoThrow(try q.enqueue(data[0]))
        XCTAssertThrowsError(try q.enqueue(data[1]))
        XCTAssertEqual(q.count, 1)
        
        q = ArrayQueue<Entry>(maxCapacity: 0)
        XCTAssertThrowsError(try q.enqueue(data[0]))
        XCTAssertEqual(q.count, 0)
    }

    static var allTests = [
        ("testQueue", testQueue),
        ("testIteration", testIteration),
        ("testContains", testContains),
        ("testRemove", testRemove),
        ("testMaxCapacity", testMaxCapacity),        
    ]
}
