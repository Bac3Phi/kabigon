import Foundation

/// The JSON Codex writes to a command hook's stdin. Codex has evolved its hook
/// payload fields over time, so this decoder accepts the documented/common
/// spellings Kabigon needs instead of tying the app to Claude's exact schema.
public struct CodexHookPayload: Decodable, Equatable {
    public let sessionId: String?
    public let project: String?
    public let hookEventName: String?
    public let message: String?
    public let toolName: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case threadId = "thread_id"
        case conversationId = "conversation_id"
        case turnId = "turn_id"
        case cwd
        case project
        case workspaceRoot = "workspace_root"
        case hookEventName = "hook_event_name"
        case eventName = "event_name"
        case event
        case hookEvent = "hook_event"
        case message
        case prompt
        case lastAssistantMessage = "last_assistant_message"
        case toolName = "tool_name"
        case tool
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = Self.firstString(c, [.sessionId, .threadId, .conversationId, .turnId])
        project = Self.firstString(c, [.cwd, .project, .workspaceRoot])
        hookEventName = Self.firstString(c, [.hookEventName, .eventName, .event, .hookEvent])
        message = Self.firstString(c, [.message, .lastAssistantMessage, .prompt])
        toolName = Self.firstString(c, [.toolName, .tool])
    }

    public init(sessionId: String?, project: String?, hookEventName: String?, message: String?, toolName: String?) {
        self.sessionId = sessionId
        self.project = project
        self.hookEventName = hookEventName
        self.message = message
        self.toolName = toolName
    }

    private static func firstString(_ c: KeyedDecodingContainer<CodingKeys>, _ keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? c.decode(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    public static func decode(from data: Data) -> CodexHookPayload? {
        try? JSONDecoder().decode(CodexHookPayload.self, from: data)
    }

    public func makeEvent(now: Date) -> AgentEvent? {
        guard let sessionId, let hookEventName else { return nil }
        let context = message ?? toolName.map { "Using \($0)" }
        return AgentEvent(
            sessionId: sessionId, agentKind: .codex, eventName: hookEventName,
            project: project, message: context, timestamp: now
        )
    }
}

/// The JSON Auggie writes to a command hook's stdin.
public struct AugmentHookPayload: Decodable, Equatable {
    public let conversationId: String?
    public let workspaceRoots: [String]?
    public let hookEventName: String?
    public let message: String?
    public let toolName: String?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case workspaceRoots = "workspace_roots"
        case hookEventName = "hook_event_name"
        case message
        case toolName = "tool_name"
    }

    public static func decode(from data: Data) -> AugmentHookPayload? {
        try? JSONDecoder().decode(AugmentHookPayload.self, from: data)
    }

    public func makeEvent(now: Date) -> AgentEvent? {
        guard let conversationId, let hookEventName else { return nil }
        let context = message ?? toolName.map { "Using \($0)" }
        return AgentEvent(
            sessionId: conversationId, agentKind: .augment, eventName: hookEventName,
            project: workspaceRoots?.first, message: context, timestamp: now
        )
    }
}

/// The JSON Cursor writes to a hook's stdin (only the fields Kabigon needs).
public struct CursorHookPayload: Decodable, Equatable {
    public let conversationId: String?
    public let hookEventName: String?
    public let workspaceRoots: [String]?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case hookEventName = "hook_event_name"
        case workspaceRoots = "workspace_roots"
    }

    public static func decode(from data: Data) -> CursorHookPayload? {
        try? JSONDecoder().decode(CursorHookPayload.self, from: data)
    }

    public func makeEvent(now: Date) -> AgentEvent? {
        guard let conversationId, let hookEventName else { return nil }
        return AgentEvent(
            sessionId: conversationId, agentKind: .cursor, eventName: hookEventName,
            project: workspaceRoots?.first, message: nil, timestamp: now
        )
    }
}

/// The JSON Windsurf (Cascade) writes to a hook's stdin.
public struct WindsurfHookPayload: Decodable, Equatable {
    public let trajectoryId: String?
    public let agentActionName: String?

    enum CodingKeys: String, CodingKey {
        case trajectoryId = "trajectory_id"
        case agentActionName = "agent_action_name"
    }

    public static func decode(from data: Data) -> WindsurfHookPayload? {
        try? JSONDecoder().decode(WindsurfHookPayload.self, from: data)
    }

    public func makeEvent(now: Date) -> AgentEvent? {
        guard let trajectoryId, let agentActionName else { return nil }
        return AgentEvent(
            sessionId: trajectoryId, agentKind: .windsurf, eventName: agentActionName,
            project: nil, message: nil, timestamp: now
        )
    }
}

/// Decodes a hook's stdin payload into an `AgentEvent`, choosing the field
/// convention by agent kind. opencode sends explicit flags instead of stdin.
public enum HookPayload {
    public static func event(forAgent kind: AgentKind, stdin data: Data, now: Date) -> AgentEvent? {
        switch kind {
        case .cursor:
            return CursorHookPayload.decode(from: data)?.makeEvent(now: now)
        case .windsurf:
            return WindsurfHookPayload.decode(from: data)?.makeEvent(now: now)
        case .codex:
            return CodexHookPayload.decode(from: data)?.makeEvent(now: now)
        case .augment:
            return AugmentHookPayload.decode(from: data)?.makeEvent(now: now)
        default:
            return ClaudeHookPayload.decode(from: data)?.makeEvent(now: now, kind: kind)
        }
    }
}
