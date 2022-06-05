import Foundation

// Read command-line arguments

// Create ChatServer

// Run ChatServer

import Socket
import Foundation
import ChatMessage
import Collections

var offset: Int = 0
var recibedType: ChatMessage



let port = Int(CommandLine.arguments[1])!
let readMaxCapacity = Int(CommandLine.arguments[2])!

if readMaxCapacity >= 2 && readMaxCapacity <= 50 {
    do{
        let chatServer = try ChatServer(port: port)

        try chatServer.run()

    } catch let error {
        print("Connection error: \(error)")
    }
} else {
    print("Invalid value for MaxCapacity")
}
