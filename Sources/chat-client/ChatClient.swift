//
//  ChatClient.swift
//

import Foundation
import Socket
import ChatMessage
import Dispatch
import Glibc

enum ChatClientError: Error {
    case wrongAddress
    case networkError(socketError: Error)
    case protocolError
    case timeout        // Thrown when the server does not respond to Init after 10s
}

class ChatClient {
    let host: String
    let port: Int
    let nick: String
    
    init(host: String, port: Int, nick: String) {
        self.host = host
        self.port = port
        self.nick = nick
    }
        
    func run() throws {
        var nonStop: Bool = true
        var ftu: Bool = true

        guard let serverAddress = Socket.createAddress(for: host, on: Int32(port)) else {
            throw ChatClientError.wrongAddress
        }
        let clientSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
        try clientSocket.setReadTimeout(value: 10 + 1000)
        var writeBuffer = Data(capacity: 1000)
        var readBuffer = Data(capacity: 1000)

        while nonStop {
            do{
                                
                if ftu {
                    let initMessage = InitMessage(type: ChatMessage.Init, nick: nick)
                    withUnsafeBytes(of: initMessage.type) { writeBuffer.append(contentsOf: $0) }
                    initMessage.nick.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                    ftu = false
                    try clientSocket.write(from: writeBuffer, to: serverAddress)         

                    // -- receive WELCOME message
                    var offset = 0
                    readBuffer.removeAll()
                    let (bytesRead, _) = try clientSocket.readDatagram(into: &readBuffer)
                    guard bytesRead != 0 else {
                        print("Server unreachable")
                        return nonStop = false
                    }
                    let typeReceived = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) } 

                    // -- check it's a WELCOME message
                    guard typeReceived == ChatMessage.Welcome else { 
                        throw ChatClientError.protocolError
                    }
                    offset += MemoryLayout<ChatMessage>.size
                    let accepted = readBuffer.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Bool.self) } 
                    if accepted {
                        print("Mini-Chat v2.0: Welcome \(nick)")                        
                    } else {
                        print("Mini-Chat v2.0: IGNORED new user \(nick), nick already used")
                        nonStop = false
                    }
                    readBuffer.removeAll()

                } else {
                    print(">> ", terminator:"")
                    writeBuffer.removeAll()
                    let message = WriterMessage(type: ChatMessage.Writer, nick: nick, text: readLine()!)
                    if message.text != ".quit" {
                        withUnsafeBytes(of: message.type) { writeBuffer.append(contentsOf: $0) }
                        message.nick.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                        message.text.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                        try clientSocket.write(from: writeBuffer, to: serverAddress)
                        writeBuffer.removeAll()
                    } else {
                        readBuffer.removeAll()
                        let message = LogoutMessage(type: ChatMessage.Logout, nick: nick)
                        withUnsafeBytes(of: message.type) { writeBuffer.append(contentsOf: $0) }
                        message.nick.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                        try clientSocket.write(from: writeBuffer, to: serverAddress)
                        writeBuffer.removeAll()
                        nonStop = false
                    }
                    readBuffer.removeAll()
                }
                
                // -- receive messages in background
                let _ = DatagramReader(socket: clientSocket, capacity: 2048) { (buffer, bytesRead, address) in 
                    self.handler(buffer: buffer, bytesRead: bytesRead, address:address!, clientSocket: clientSocket)
                }

            } catch let error {
                    throw ChatClientError.networkError(socketError: error)
            }
        }
    }
}

// Add additional functions using extensions
extension ChatClient {
    func handler(buffer: Data, bytesRead: Int, address: Socket.Address, clientSocket: Socket){
        
        var readBuffer = buffer 
        var offset = 0
           
        do{
            // -- receive type of message       
            let typeReceived = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) }            
            offset += MemoryLayout<ChatMessage>.size
            
            // -- check if it's a server message
            guard typeReceived == ChatMessage.Server else { 
                throw ChatClientError.protocolError
            }

            let nickReceived = readBuffer.advanced(by:offset).withUnsafeBytes { String(cString: $0.bindMemory(to: UInt8.self).baseAddress!) }            
            offset += MemoryLayout<String>.size 

            let textReceived = readBuffer.advanced(by:offset).withUnsafeBytes { String(cString: $0.bindMemory(to: UInt8.self).baseAddress!) }            

            print()
            print("\(nickReceived): \(textReceived)")
            print(">> ", terminator:"")
            fflush(stdout)
            readBuffer.removeAll()
        } catch let error {
            print("\(error)")
        }
    }
}