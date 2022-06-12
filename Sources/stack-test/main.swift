import Collections

let maxCapacityTest = 20
var stackTest = ArrayStack<Int>()

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

func processAll<S: Stack>(stack: inout S) {
    var t: S.Element? 
    print("removed: ", terminator:"")

    repeat {
        t = stack.pop()
        if t != nil {
            print("\(t!) ", terminator:"")
        }
    } while t != nil
    print()
}

func fillStack(stack: ArrayStack<Int>, n: Int) {
    var i = 1
    repeat {
        stackTest.push(i)
        i = i + 1
    } while i <= n
}


// -- Scenario 1: Stack items
print("Scenario 1: add items to the stack")
var size = 10
fillStack(stack: stackTest, n: size)
print(stackTest)
print("----------------------")

// -- Scenario 2: Remove items
print("Scenario 2: remove items form the stack")
size = 10
processAll(stack: &stackTest)
print(stackTest)
print("----------------------")

// -- Scenario 3: forEach function
print("Scenario 3: forEach functionality")
var stackTestString = ArrayStack<String>()
stackTestString.push("uno")
stackTestString.push("dos")
stackTestString.push("tres")
stackTestString.push("cuatro")
stackTestString.push("cinco")
stackTestString.forEach { print($0.uppercased()) }
print("----------------------")