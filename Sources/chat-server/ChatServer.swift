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
            //let serverSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)

            // recepción de mensajes en hilo paralelo
            self.datagramReader = DatagramReader(socket: self.serverSocket, capacity: 1024){ (buffer, bytesRead, address) in 
                self.handler(buffer: buffer, bytesRead: bytesRead, address:address!)

            }

            func convertDate(_ date: Date) -> String{
                let df = DateFormatter()
                df.dateFormat = "yy-MMM-dd HH:mm"
                return df.string(from: date)
            }


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
            var writeBuffer = Data(capacity: 1024)

            

            func checkCapacity(_ value: Int) throws { 
               if value >= clients.maxCapacity {
                    throw CollectionsError.maxCapacityReached
                }
            }



            // -- recibir tipo de mensaje
            var offset: Int = 0
            let typeReceived = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) }            
            offset += MemoryLayout<ChatMessage>.size

            // -- recibir Nick
            let nickReceived = readBuffer.advanced(by:offset).withUnsafeBytes {
                String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
            }            
            offset += nickReceived.count + 1

                    


            switch typeReceived {
            case .Init:
                
                do {
                    // -- verify the capacity of client list and if the nick is already used
                    try checkCapacity(clients.count)
                    let repeatedClient = clients.contains {$0.nick == nickReceived}
                    let welcomeMessage = WelcomeMessage(type: ChatMessage.Welcome, accepted: !(repeatedClient))
                    if !repeatedClient {
                        clients.enqueue(ActiveClient(nick: nickReceived, address: address, lastUpdateTime: Date()))
                        print("INIT received from \(nickReceived)")                        
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

                    // -- send a message to other clients
                    offset = 0
                    let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(nickReceived) joins")
                    withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                    withUnsafeBytes(of: serverMessage.text) { writeBuffer.append(contentsOf: $0) }
                    try clients.forEach { client in
                        if client.nick != nickReceived {
                            try self.serverSocket.write(from: writeBuffer, to: client.address)
                            //print("\(client.address)")
                        }
                    }
                    writeBuffer.removeAll()
                } catch {
                    print("\(error)")
                }
                
                

            case .Logout:
                print("LOGOUT received from \(nickReceived)")
                // -- add client to OLD CLIENTS list
                inactiveClients.push(OldClient(nick: nickReceived, lastUpdateTime: Date()))
                // -- remevo the client from ACTIVE CLIENTS list
                clients.remove {$0.nick == nickReceived}
                // -- send a message to other clients
                writeBuffer.removeAll()
                offset = 0
                let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(nickReceived) leaves")
                withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.text) { writeBuffer.append(contentsOf: $0) }
                try clients.forEach { client in
                    if client.nick != nickReceived {
                        try self.serverSocket.write(from: writeBuffer, to: client.address)
                        //print("\(client.address)")
                    }
                }
                writeBuffer.removeAll()

                
            
            default:
                // -- recibir Text
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
                withUnsafeBytes(of: serverMessage.text) { writeBuffer.append(contentsOf: $0) }
                
                // -- update date of the client
                clients.remove {$0.nick == nickReceived}
                clients.enqueue(ActiveClient(nick: nickReceived, address: address, lastUpdateTime: Date()))

                // -- send message to all clients
                try clients.forEach { client in
                    if client.nick != nickReceived {
                        try self.serverSocket.write(from: writeBuffer, to: client.address)
                        //print("\(client.address)")
                    }
                    
                }
                
                writeBuffer.removeAll()

            }
            readBuffer.removeAll()
            //print("\(clients)")
        } catch let error { 
            print("Connection error: \(error)")
        }
    }
}


