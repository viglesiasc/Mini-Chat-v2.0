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
        // Your code here
        
        var nonStop: Bool = true
        var ftu: Bool = true
        while nonStop {
            do{
                guard let serverAddress = Socket.createAddress(for: host, on: Int32(port)) else {
                    print("Error creating Address")
                    exit(1)
                }
                let clientSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
                var writeBuffer = Data(capacity: 1000)
                var readBuffer = Data(capacity: 1000)
                
                if ftu {
                    let initMessage = InitMessage(type: ChatMessage.Init, nick: nick)
                    withUnsafeBytes(of: initMessage.type) { writeBuffer.append(contentsOf: $0) }
                    initMessage.nick.utf8CString.withUnsafeBytes { writeBuffer.append(contentsOf: $0) }
                    ftu = false
                    try clientSocket.write(from: writeBuffer, to: serverAddress)         

                    // -- recibir mensaje WELCOME  
                    var offset = 0
                    readBuffer.removeAll()
                    let (bytesRead, _) = try clientSocket.readDatagram(into: &readBuffer)
                    let recibedType = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) } 
                    offset += MemoryLayout<ChatMessage>.size
                    let accepted = readBuffer.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Bool.self) } 
                    //offset += MemoryLayout<Bool>.size
                    if accepted {
                        print("Mini-Chat v2.0: Welcome \(nick)")                        
                    }   
                    readBuffer.removeAll()

                } else {
                    
                    let _ = DatagramReader(socket: clientSocket, capacity: 1024) { (buffer, bytesRead, address) in 
                        self.handler(buffer: buffer, bytesRead: bytesRead, address:address!, clientSocket: clientSocket)
                    }
                    
                    print(">> ", terminator:"")
                    fflush(stdout)
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
                
            } catch let error {
                    print("Connection error: \(error)")
            }
        }
    }
}

// Add additional functions using extensions

extension ChatClient {
    func handler(buffer: Data, bytesRead: Int, address: Socket.Address, clientSocket: Socket){
        
        var readBuffer = buffer
                
        var offset = 0
           
        // -- recibir tipo de mensaje        
        let recibedType = readBuffer.withUnsafeBytes { $0.load(as: ChatMessage.self) }            
        offset += MemoryLayout<ChatMessage>.size

        let recibedNick = readBuffer.advanced(by:offset).withUnsafeBytes { String(cString: $0.bindMemory(to: UInt8.self).baseAddress!) }            
        offset += MemoryLayout<String>.size 

        let recibedText = readBuffer.advanced(by:offset).withUnsafeBytes { String(cString: $0.bindMemory(to: UInt8.self).baseAddress!) }            
        offset += MemoryLayout<String>.size  

        
        
        print("\(recibedNick): \(recibedText)")
        //fflush(stdout)

        readBuffer.removeAll()
    }
    
}