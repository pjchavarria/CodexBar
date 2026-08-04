import Testing
@testable import CodexBar

struct CodexBarLaunchModeTests {
    @Test
    func `normal launch starts the application`() {
        #expect(CodexBarLaunchMode.resolve(arguments: ["/Applications/CodexBar"]) == .application)
    }

    @Test
    func `hook event launch skips application initialization`() {
        #expect(CodexBarLaunchMode.resolve(
            arguments: ["/Applications/CodexBar", "--hook-event"]) == .hookEvent)
    }

    @Test
    func `hook event is recognized among other arguments`() {
        #expect(CodexBarLaunchMode.resolve(
            arguments: ["/Applications/CodexBar", "--verbose", "--hook-event"]) == .hookEvent)
    }

    @Test
    func `similar argument still starts the application`() {
        #expect(CodexBarLaunchMode.resolve(
            arguments: ["/Applications/CodexBar", "--hook-events"]) == .application)
    }

    @Test
    func `route B strips launcher account scope before discovery`() {
        let environment = [
            "CODEX_HOME": "/tmp/codex-account",
            "CLAUDE_CONFIG_DIR": "/tmp/claude-account",
            "PATH": "/usr/bin:/bin",
        ]

        #expect(CodexBarPersonalization.sanitizedLaunchEnvironment(
            featureEnabled: true,
            environment: environment) == ["PATH": "/usr/bin:/bin"])
        #expect(CodexBarPersonalization.sanitizedLaunchEnvironment(
            featureEnabled: false,
            environment: environment) == environment)
    }
}
