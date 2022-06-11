//
//  ChatServer.swift
//

import Foundation
import Socket
import ChatMessage
import Collections

// Your code here

enum ChatServerError: Error {
    /**
     Thrown on communications error.
     Initialize with the underlying Error thrown by the Socket library.
     */
    case networkError(socketError: Error)
    
    /**
     Thrown if an unexpected message or argument is received.
     For example, the server should never receive a 'Server' message.
     */
    case protocolError
}


class ChatServer {
    let port: Int
    var serverSocket: Socket
    var datagramReader: DatagramReader? = nil

    
    public struct ActiveClient {
        var nick: String
        var address: Socket.Address
        var lastUpdateTime: Date
        
        public init(nick: String, address: Socket.Address, lastUpdateTime: Date) {
            self.nick = nick
            self.address = address
            self.lastUpdateTime = lastUpdateTime 

        }
    } 

    public struct OldClient {
        var nick: String
        var lastUpdateTime: Date
        
        public init(nick: String, lastUpdateTime: Date) {
            self.nick = nick
            self.lastUpdateTime = lastUpdateTime 

        }
    }

    public var clients = ArrayQueue<ActiveClient>(maxCapacity: readMaxCapacity)
    public var inactiveClients = ArrayStack<OldClient>()
    
    init(port: Int) throws {
        self.port = port
        serverSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
    }
    
    func run() throws {
        do {
            try serverSocket.listen(on: port)

            // -- receive messages in background
            self.datagramReader = DatagramReader(socket: self.serverSocket, capacity: 2048){ (buffer, bytesRead, address) in 
                self.handler(buffer: buffer, bytesRead: bytesRead, address:address!)

            }

            // -- convert the data format as we want
            func convertDate(_ date: Date) -> String{
                let df = DateFormatter()
                df.dateFormat = "yy-MMM-dd HH:mm"
                return df.string(from: date)
            }

            // -- read from the command line
            repeat{
                let adminCommand: String = readLine()!
                if adminCommand.lowercased() == "l" {
                    print("ACTIVE CLIENTS")
                    print("==============")
                    clients.forEach { client in
                        let (clientIP, clientPort) = Socket.hostnameAndPort(from: client.address)!
                        print("\(client.nick) \(clientIP):\(clientPort) \(convertDate(client.lastUpdateTime))")

                    }
                    print("")
                }
                if adminCommand.lowercased() == "o" {
                    print("OLD CLIENTS")
                    print("==============")
                    inactiveClients.forEach { client in
                        print("\(client.nick): \(convertDate(client.lastUpdateTime))")

                    }
                    print("")
                }
            } while true
            
            
        } catch let error {
            throw ChatServerError.networkError(socketError: error)
        }
    }

}



// Add additional functions using extensions
extension ChatServer {

    func handler(buffer: Data, bytesRead: Int, address: Socket.Address) {
        do{
            var readBuffer = buffer
            var writeBuffer = Data(capacity: 2048)

            func checkCapacity(_ value: Int) throws { 
               if value > clients.maxCapacity {
                    throw CollectionsError.maxCapacityReached
                }
            }

            // -- receive message type
            var offset: Int = 0
            let typeReceived = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) }            
            offset += MemoryLayout<ChatMessage>.size

            // -- receive nick
            let nickReceived = readBuffer.advanced(by:offset).withUnsafeBytes {
                String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
            }            
            offset += nickReceived.count + 1

            // -- depending on the type of the message...
            switch typeReceived {
            case .Init:
                // -- check protocol
                guard typeReceived == ChatMessage.Init else { 
                    throw ChatServerError.protocolError
                }
                do {
                    // -- verify if the new client nick is already in the chat
                    let repeatedClient = clients.contains {$0.nick == nickReceived}
                    let welcomeMessage = WelcomeMessage(type: ChatMessage.Welcome, accepted: !(repeatedClient))
                    if !repeatedClient {
                        try! clients.enqueue(ActiveClient(nick: nickReceived, address: address, lastUpdateTime: Date()))
                        print("INIT received from \(nickReceived): ACCEPTED")   
                        // -- send a message to other clients
                        writeBuffer.removeAll()
                        offset = 0
                        let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(nickReceived) joins the chat")
                        withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                        withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                        serverMessage.text.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                        try clients.forEach { client in
                            if client.nick != nickReceived {
                                try self.serverSocket.write(from: writeBuffer, to: client.address)
                            }
                        }
                        writeBuffer.removeAll()                     
                    } else {
                        print("INIT received from \(nickReceived): IGNORED. Nick already used")
                    }

                    // -- send first message to client
                    writeBuffer.removeAll()
                    offset = 0
                    withUnsafeBytes(of: welcomeMessage.type) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: welcomeMessage.accepted) { writeBuffer.append(contentsOf: $0) }
                    try serverSocket.write(from: writeBuffer, to: address)
                    writeBuffer.removeAll()

                    // -- verify capacity
                    try checkCapacity(clients.count)
                    
                } catch {
                    // -- when maxCapacity is reached
                    let bannedClient = clients.dequeue()        // -- remove the client from ACTIVE CLIENTS list
                    inactiveClients.push(OldClient(nick: bannedClient!.nick, lastUpdateTime: Date()))  // -- add the client from OLD CLIENTS stack
                    // -- send a message to all client saying the client is banned
                    writeBuffer.removeAll()
                    offset = 0
                    let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(bannedClient!.nick) banned for being idle too long")
                    withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                    serverMessage.text.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                    try clients.forEach { client in
                        try self.serverSocket.write(from: writeBuffer, to: client.address)
                    }
                    try self.serverSocket.write(from: writeBuffer, to: bannedClient!.address)
                    writeBuffer.removeAll()
                }
                
                

            case .Logout:
                // -- check protocol
                guard typeReceived == ChatMessage.Logout else { 
                    throw ChatServerError.protocolError
                }
                let isKnownclient = clients.contains {$0.nick == nickReceived && $0.address == address}
                if isKnownclient {
                    print("LOGOUT received from \(nickReceived)")
                    // -- add client to OLD CLIENTS list
                    inactiveClients.push(OldClient(nick: nickReceived, lastUpdateTime: Date()))
                    // -- remove the client from ACTIVE CLIENTS list
                    clients.remove {$0.nick == nickReceived}
                    // -- send a message to other clients
                    writeBuffer.removeAll()
                    offset = 0
                    let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(nickReceived) leaves the chat")
                    withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                    serverMessage.text.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                    try clients.forEach { client in
                        if client.nick != nickReceived {
                            try self.serverSocket.write(from: writeBuffer, to: client.address)
                        }
                    }
                    writeBuffer.removeAll()
                } else {
                    print("LOGOUT received from unknown client. IGNORED")
                }
                
            
            default:
                // -- check protocol
                guard typeReceived == ChatMessage.Writer else { 
                    throw ChatServerError.protocolError
                }
                // -- check if the client is in the chat
                let isKnownclient = clients.contains { $0.nick == nickReceived && $0.address == address }
                if isKnownclient {
                    // -- receive text
                    let textReceived = readBuffer.advanced(by:offset).withUnsafeBytes {
                        String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
                    } 
                    print("WRITER received from \(nickReceived): \(textReceived)")

                    // -- build response message to all clients
                    writeBuffer.removeAll()
                    offset = 0
                    let serverMessage = ServerMessage(type: ChatMessage.Server, nick: nickReceived, text: textReceived)
                    withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                    serverMessage.text.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                    
                    // -- update date of the client
                    clients.remove {$0.nick == nickReceived}
                    try! clients.enqueue(ActiveClient(nick: nickReceived, address: address, lastUpdateTime: Date()))

                    // -- send message to all clients
                    try clients.forEach { client in
                        if client.nick != nickReceived {
                            try self.serverSocket.write(from: writeBuffer, to: client.address)
                        }
                    }
                    writeBuffer.removeAll()
                } else {
                    print("WRITER received from unknown client. IGNORED")
                }
            }
            readBuffer.removeAll()
        } catch let error { 
            print("Connection error: \(error)")
        }
    }
}


