import Collections

let maxCapacityTest = 20
var queueTest = ArrayQueue<Int>(maxCapacity: maxCapacityTest)

func scenarioResult(scenario: Int, result: Bool) {
    print("Scenario \(scenario): ", terminator:"")
    if result {
        print("PASSED")
        print("----------------------")
    } else {
        print("FAIL")
        print("----------------------")
    }
}

func processAll<S: Queue>(queue: inout S) {
    var t: S.Element?
    print("removed: ", terminator:"")
    while queue.count != 0 {
        t = queue.dequeue()
    //    if t != nil {
            print("\(t!) ", terminator:"")
        //}
    } 
    print()
}

func fillCollection(queue: ArrayQueue<Int>, n: Int) throws{
    var i = 1
    do {
        repeat {
            try queueTest.enqueue(i)
            i = i + 1
        } while i <= n
    } catch CollectionsError.maxCapacityReached{
        print("Max capactiy reached")
    }
    
}

// -- Scenario 1: Enqueue items
var size = 2
try fillCollection(queue: queueTest, n: size)
print(queueTest)
if queueTest.count == size {
    scenarioResult(scenario: 1, result: true)
} else {
    scenarioResult(scenario: 1, result: false)
}

// -- Scenario 2: Dequeue items

processAll(queue: &queueTest)
print(queueTest)
if queueTest.count == 0 {
    scenarioResult(scenario: 2, result: true)
} else {
    scenarioResult(scenario: 2, result: false)
}

// -- Scenario 3: Max capacity

try fillCollection(queue: queueTest, n: 100000)
print(queueTest)
if queueTest.count > maxCapacityTest {
    scenarioResult(scenario: 3, result: false)
} else {
    scenarioResult(scenario: 3, result: true)
}

// -- Scenario 4: Remove items

processAll(queue: &queueTest)

let value4 = 10
try fillCollection(queue: queueTest, n: value4)

for _ in 1...value4 {
    queueTest.remove {$0 % 2 == 0}
}
print(queueTest)
if queueTest.count == value4/2 {
    scenarioResult(scenario: 4, result: true)
} else {
    scenarioResult(scenario: 4, result: false)
}

// -- Scenario 5: forEach function
print("Scenario 5: ")
var queueTestString = ArrayQueue<String>(maxCapacity: maxCapacityTest)
try queueTestString.enqueue("uno")
try queueTestString.enqueue("dos")
try queueTestString.enqueue("tres")
try queueTestString.enqueue("cuatro")
try queueTestString.enqueue("cinco")
queueTestString.forEach { print($0.uppercased()) }
print("----------------------")


// -- Scenario 6: Verify contains functionality
//print("Scenario 6: ")
processAll(queue: &queueTest)
let size6 = 15
try fillCollection(queue: queueTest, n: size6)
print(queueTest)
var f = 1
var isPresent: Bool = queueTest.contains {$0 == f }
repeat {
    if isPresent {
        print("Contains \(f)")
        f = f + 1
    }
} while f <= size6
if isPresent {
    scenarioResult(scenario: 6, result: true)
} else {
    scenarioResult(scenario: 6, result: false)
}

