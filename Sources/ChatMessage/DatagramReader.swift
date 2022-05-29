//
//  DatagramReader.swift
//

import Foundation
import Socket

/**
 * Simple helper class to read forever from a socket using a background queue.
 * TODO:
 * - Error handling.
 * - Copy buffer and send results on main thread.
 * - Make it stoppable.
 */
public class DatagramReader {
    enum DatagramReaderError : Error {
        case timeout
    }
    
    func readDatagram(from socket: Socket, into buffer: inout Data) throws -> (bytesRead: Int, address: Socket.Address?) {
        let (bytesRead, address) = try socket.readDatagram(into: &buffer)
        if bytesRead == 0 && errno == EAGAIN {
            throw DatagramReaderError.timeout
        }
        return (bytesRead, address)
    }

    /** Creates a DatagramReader and read datagrams forever in a loop. */
    public init(socket: Socket, capacity: Int, handler: @escaping (Data, Int, Socket.Address?) -> Void) {
        var buffer = Data(capacity: capacity)
        
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async {
            repeat {
                buffer.removeAll()
                do {
                    let (bytesRead, address) = try self.readDatagram(from: socket, into: &buffer)
                    handler(buffer, bytesRead, address)        // TODO: main queue, buffer copy
                } catch DatagramReaderError.timeout {
                    // Ignored
                } catch {
                    /// TODO: error handling
                    fatalError("Communications error: \(error)")
                }
            } while true
        }
    }
    
    public convenience init(socket: Socket, capacity: Int, handler: @escaping (Data) -> Void) {
        self.init(socket: socket, capacity: capacity) { buffer, _, _ in
            handler(buffer)
        }
    }
}
