import Foundation


import Foundation
import Socket
import ChatMessage
import Glibc


let readHost = CommandLine.arguments[1]
let readPort = Int(CommandLine.arguments[2])!
let readNick = CommandLine.arguments[3]


do{
    let chatClient = ChatClient(host: readHost, port: readPort, nick: readNick)

    try chatClient.run()

 } catch let error {
     print("Connection error: \(error)")
 }

