import Foundation

// Read command-line arguments

// Create ChatClient

// Run ChatClient

import Foundation
import Socket
import ChatMessage
import Glibc

// Read command-line argumens

// Create ChatClient

// Run ChatClient


//mi codigo...



let readHost = CommandLine.arguments[1]
let readPort = Int(CommandLine.arguments[2])!
let readNick = CommandLine.arguments[3]


do{
    let chatClient = ChatClient(host: readHost, port: readPort, nick: readNick)

    try chatClient.run()

 } catch let error {
     print("Connection error: \(error)")
 }

