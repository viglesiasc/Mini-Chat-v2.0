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

    
    
    //var readers = ClientCollectionArray(uniqueNicks: false)
    //var writers = ClientCollectionArray(uniqueNicks: true)
    
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

            repeat{
                let adminCommand: String = readLine()!
                if adminCommand.lowercased() == "l" {
                    print("ACTIVE CLIENTS")
                    print("==============")
                }
                if adminCommand.lowercased() == "o" {
                    print("OLD CLIENTS")
                    print("==============")
                }
            } while true
            
            
        } catch let error {
            throw ChatServerError.networkError(socketError: error)
        }
    }

}

//var clients = ArrayQueue<Int>()

// Add additional functions using extensions
extension ChatServer {
    func handler(buffer: Data, bytesRead: Int, address: Socket.Address) {
        do{
            var readBuffer = buffer
            var writeBuffer = Data(capacity: 1024)

            
                
            // -- recibir tipo de mensaje
            var offset: Int = 0
            
            let recibedType = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) }            
            offset += MemoryLayout<ChatMessage>.size

            // -- recibir Nick
            let recibedNick = readBuffer.advanced(by:offset).withUnsafeBytes {
                String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
            }            
            offset += recibedNick.count + 1

                    


            switch recibedType {
            case .Init:
                print("INIT received from \(recibedNick)")
                //clients.enqueue(recibedNick)
                writeBuffer.removeAll()
                offset = 0
                let welcomeMessage = WelcomeMessage(type: ChatMessage.Welcome, accepted: true)
                withUnsafeBytes(of: welcomeMessage.type) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: welcomeMessage.accepted) { writeBuffer.append(contentsOf: $0) }
                try serverSocket.write(from: writeBuffer, to: address)
                writeBuffer.removeAll()

            case .Logout:
                print("LOGOUT received from \(recibedNick)")
                //clients.enqueue(recibedNick)
                writeBuffer.removeAll()
                offset = 0
                let serverMessage = ServerMessage(type: ChatMessage.Server, nick: "server", text: "\(recibedNick) leaves ")
                withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.text) { writeBuffer.append(contentsOf: $0) }
                try serverSocket.write(from: writeBuffer, to: address)
                writeBuffer.removeAll()
            
            default:
                // -- recibir Text
                let recibedText = readBuffer.advanced(by:offset).withUnsafeBytes {
                    String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
                } 
                print("WRITER received from \(recibedNick): \(recibedText)")
                writeBuffer.removeAll()
                offset = 0
                let serverMessage = ServerMessage(type: ChatMessage.Server, nick: recibedNick, text: recibedText)
                withUnsafeBytes(of: serverMessage.type) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.nick) { writeBuffer.append(contentsOf: $0) }
                withUnsafeBytes(of: serverMessage.text) { writeBuffer.append(contentsOf: $0) }
                try serverSocket.write(from: writeBuffer, to: address)
                writeBuffer.removeAll()
                //print("holaaa")
                //print("\(recibedText)")
            }
            readBuffer.removeAll()
        } catch let error { 
            print("Connection error: \(error)")
        }
    }
}


