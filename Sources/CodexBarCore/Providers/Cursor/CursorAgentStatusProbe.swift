import Foundation

enum CursorAgentStatusProbeError: LocalizedError, Sendable {
    case invalidResponse
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Could not read Cursor Agent authentication status."
        case .notAuthenticated:
            "Cursor Agent is not authenticated. Run 'cursor-agent login'."
        }
    }
}

struct CursorAgentStatusResponse: Decodable, Equatable, Sendable {
    struct UserInfo: Decodable, Equatable, Sendable {
        let email: String?
        let userId: String?

        private enum CodingKeys: String, CodingKey {
            case email
            case userId
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.email = try container.decodeIfPresent(String.self, forKey: .email)
            if let stringID = try? container.decodeIfPresent(String.self, forKey: .userId) {
                self.userId = stringID
            } else if let integerID = try? container.decodeIfPresent(Int.self, forKey: .userId) {
                self.userId = String(integerID)
            } else {
                self.userId = nil
            }
        }
    }

    let isAuthenticated: Bool
    let userInfo: UserInfo?
}

struct CursorAgentStatusProbe: Sendable {
    private static let commandTimeout: TimeInterval = 10

    func fetch(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        now: Date = Date()) async throws -> UsageSnapshot
    {
        let loginPATH = LoginShellPathCache.shared.current
        guard let executable = BinaryLocator.resolveCursorAgentBinary(
            env: environment,
            loginPATH: loginPATH)
        else {
            throw SubprocessRunnerError.binaryNotFound("cursor-agent")
        }

        var commandEnvironment = environment
        commandEnvironment["NO_COLOR"] = "1"
        commandEnvironment["PATH"] = PathBuilder.effectivePATH(
            purposes: [.tty, .nodeTooling],
            env: environment,
            loginPATH: loginPATH)

        let result = try await SubprocessRunner.run(
            binary: executable,
            arguments: ["status", "--format", "json"],
            environment: commandEnvironment,
            timeout: Self.commandTimeout,
            standardInput: FileHandle.nullDevice,
            label: "cursor-agent-status")
        guard let data = result.stdout.data(using: .utf8) else {
            throw CursorAgentStatusProbeError.invalidResponse
        }
        let status: CursorAgentStatusResponse
        do {
            status = try JSONDecoder().decode(CursorAgentStatusResponse.self, from: data)
        } catch {
            throw CursorAgentStatusProbeError.invalidResponse
        }
        guard status.isAuthenticated else {
            throw CursorAgentStatusProbeError.notAuthenticated
        }

        return UsageSnapshot(
            primary: nil,
            secondary: nil,
            tertiary: nil,
            updatedAt: now,
            identity: ProviderIdentitySnapshot(
                providerID: .cursor,
                accountEmail: status.userInfo?.email,
                accountOrganization: nil,
                loginMethod: "Cursor Agent",
                accountID: status.userInfo?.userId))
    }
}

struct CursorAgentStatusFetchStrategy: ProviderFetchStrategy {
    let id: String = "cursor.agent-status"
    let kind: ProviderFetchKind = .cli

    func isAvailable(_ context: ProviderFetchContext) async -> Bool {
        BinaryLocator.resolveCursorAgentBinary(env: context.env) != nil
    }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        let snapshot = try await CursorAgentStatusProbe().fetch(environment: context.env)
        return self.makeResult(
            usage: snapshot,
            sourceLabel: "cursor-agent",
            diagnostic: "Cursor Agent is connected; detailed usage requires a Cursor web or app session.")
    }

    func shouldFallback(on _: Error, context _: ProviderFetchContext) -> Bool {
        false
    }
}
