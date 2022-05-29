public enum ChatMessage {
    case Init
    case Welcome
    case Writer
    case Server
    case Logout
}

public class InitMessage {
    public var type: ChatMessage
    public var nick: String
    public init(type: ChatMessage, nick: String) {
        self.type = type
        self.nick = nick
    }
}

public class WelcomeMessage {
    public var type: ChatMessage
    public var accepted: Bool
    public init(type: ChatMessage, accepted: Bool) {
        self.type = type
        self.accepted = accepted
    }
}

public class WriterMessage {
    public var type: ChatMessage
    public var nick: String
    public var text: String
    public init(type: ChatMessage, nick: String, text: String) {
        self.type = type
        self.nick = nick
        self.text = text
    }
}

public class ServerMessage {
    public var type: ChatMessage
    public var nick: String
    public var text: String
    public init(type: ChatMessage, nick: String, text: String) {
        self.type = type
        self.nick = nick
        self.text = text
    }
}

public class LogoutMessage {
    public var type: ChatMessage
    public var nick: String
    public init(type: ChatMessage, nick: String) {
        self.type = type
        self.nick = nick
    }
}