_Status: building · 2026-08-06_

# Standalone App and Mac App Store Release

## Resume here

Choose the final product name, create a new repository and sandboxed native app, then land one vertical slice: menu-bar
shell, fixture-backed account cards, and the provider-colored aggregate chart. Keep the installed fork running only as
the behavior oracle while the replacement is incomplete.

## Locked outcome

- The Mac App Store is the standalone app's intended public release channel.
- The sellable product remains the 420-point, two-column complete-provider account grid described by
  [PD-009 and PD-012](product-decisions.md).
- App Store work may replace provider acquisition mechanisms, but it does not silently remove Codex, Claude, Cursor,
  Grok, Antigravity, configured accounts, truthful errors, or the provider-colored aggregate chart.
- Distributed copies retain the upstream MIT license and copyright notice.
- The new repository does not import upstream application architecture. Reuse is admitted file by file only after its
  dependency closure, license notice, and product need are explicit.

## Confirmed release gate

The current fork application is not App Store ready. Its application entitlement file does not enable
`com.apple.security.app-sandbox`, and the installed bundle has no sandbox entitlement. The provider layer also reads
browser cookie/local-storage databases, local account homes, and installed command-line tools. Apple's Mac App Store
rules require an appropriately sandboxed, self-contained app packaged with Apple tooling.

This is an acquisition-boundary problem, not a listing-form problem. Creating the App Store Connect record first would
not prove that the submitted binary can still populate the product.

## Standalone architecture boundary

The repository audit counted 419 Swift app files, 714 Swift test files, 65 immediate provider directories excluding
`Shared`, and an active `Sources/CodexBar/Sync` subsystem. The replacement therefore starts in a new repository instead
of adding a thin target here.

### May migrate after dependency review

- The approved account-card and aggregate-chart composition, rewritten against a small replacement domain model.
- Pure provider response models, parsers, reset calculations, and fixtures that compile without ambient settings,
  browser, process, updater, sync, or menu-controller dependencies.
- Provider colors, accessibility labels, and formatting rules that are part of the approved visible behavior.
- The upstream MIT copyright and permission notice with every copied substantial portion.

### Must not migrate

- Sparkle, widgets, iCloud/app-group sync, Claude Sync, hooks, agent-session UI, telemetry, status pages, provider tabs,
  provider submenus, alternate layouts, or the upstream settings/controller graph.
- Browser-cookie scraping, external CLI execution, unrestricted home-directory discovery, or direct-distribution helper
  assumptions as the App Store acquisition architecture.
- Providers outside Codex, Claude, Cursor, Grok, and Antigravity until the five-provider release promise is complete.

## Build sequence

1. After the final name is chosen, scaffold a new Swift 6/macOS 15+ repository with App Sandbox, outbound network access,
   a menu-bar shell, a minimal settings window, and a login item that does not activate other applications.
2. Implement the approved account-card grid and aggregate chart against deterministic fixtures; this becomes the visual
   and accessibility contract before live credentials are added.
3. Define one small provider adapter protocol around typed account identity, quota rows, errors, and chart contributions.
4. Inventory each provider path and classify every required input as one of:
   - network API or provider-supported OAuth inside the sandbox;
   - user-selected folder retained with a security-scoped bookmark;
   - helper code embedded and signed inside the application bundle;
   - incompatible current mechanism that needs a provider-specific redesign.
5. Add Antigravity first as the current in-process OAuth proof, then Codex, Claude, Cursor, and Grok only when each has a
   supported acquisition path. Prove one sandboxed fixture account per provider, then the real complete account census,
   without temporary exception
   entitlements. A temporary exception is a documented last resort, not the product architecture.
6. Run the same provider matrix and final account-card render used by the current fork. Any missing account or chart
   series fails the spike visibly.
7. Only after the provider matrix is green, create the App Store Connect app record and TestFlight build.

### Provider acquisition matrix

| Provider | Current working input | App Store path to prove | Status |
| --- | --- | --- | --- |
| Codex | Managed OAuth/web credentials, browser-session import or external Codex CLI fallback; ambient `~/.codex` session logs for the global chart | Keep managed credentials inside the app; use the in-process authenticated HTTP path; let the user select each local history folder and retain a security-scoped bookmark | Prototype required |
| Claude | External `claude-swap` account list plus Claude config homes, CLI, OAuth, or browser web session | Replace `claude-swap` execution with an in-app account store and a reviewable in-process fetch path; verify that the chosen consumer-account API/auth mechanism is provider-supported | Provider/API decision required |
| Cursor | Browser cookie database or external `cursor-agent`, followed by Cursor web usage and cost endpoints | Obtain a provider-supported in-app authorization and usage mechanism; browser-database scraping and an external agent are not the release architecture | Provider/API blocker |
| Grok | Browser cookie import and a local Grok RPC/web-billing path | Obtain a provider-supported in-app authorization and subscription-usage mechanism; keep API-key billing separate from consumer quota | Provider/API blocker |
| Antigravity | Local Antigravity/`agy` process or the existing in-process remote OAuth fetcher | Make the existing remote OAuth fetcher the sandbox path and remove the external-process dependency | Best first prototype |

The matrix records confirmed current code paths and the smallest candidate sandbox boundary. “Provider/API blocker” means
the repository does not yet contain evidence of a supported replacement; it does not mean the provider is impossible.

## Storefront and review work after the spike

- Reserve the chosen name and final bundle identifier in Certificates, Identifiers & Profiles and App Store Connect.
- Choose pricing and territories; complete the paid-app agreement, tax, and banking setup before sale.
- Publish a support URL and privacy policy under a provider-neutral business identity.
- Prepare a 1024-point App Store icon, fictional-account screenshots, description, subtitle, keywords, category, age
  rating, and accessibility/privacy answers.
- Give App Review a deterministic demo mode or review accounts for every provider-dependent feature, plus review notes
  explaining the menu-bar-only experience and provider authentication.
- Upload an archive through Xcode, complete internal TestFlight QA, then submit the first production version.

## Evidence

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — macOS sandbox,
  self-contained packaging, completeness, metadata, review access, and privacy expectations.
- [Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)
- [Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [App Store Connect workflow](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)

## Exit criteria

- The sandboxed application launches without taking focus and shows every configured test account.
- Codex, Claude, Cursor, Grok, and Antigravity return truthful quota or explicit provider-scoped errors.
- The aggregate dashboard includes every available typed provider series, including Codex.
- The app contains no updater, installer, external executable dependency, or undocumented temporary exception that App
  Review cannot exercise.
- The App Store Connect record, privacy answers, review access, screenshots, pricing, and TestFlight build are complete.

## Direction log

- 2026-08-06: The user chose the Mac App Store as the public release target after approving the QuotaRoom account-card
  product surface.
- 2026-08-06: Repository and installed-bundle inspection showed the current direct build is unsandboxed and depends on
  cross-container provider data, so the sandbox compatibility spike precedes storefront submission.
- 2026-08-06: The user rejected QuotaRoom, ended the upstream-fork product strategy, and locked a new minimal standalone
  app that preserves the approved grid, chart, and complete five-provider promise.
- 2026-08-06: A repository inventory and adversarial architecture pass upheld a new-repository boundary. The existing
  fork remains only a temporary behavior/code oracle; a compiled thin-target dependency proof is the sole evidence that
  would reopen that boundary.
