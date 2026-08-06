_Status: open proposal · 2026-08-06_

# QuotaRoom Mac App Store Release

## Resume here

Build a separate sandboxed QuotaRoom distribution target and prove the complete five-provider account grid with test
credentials before creating a production App Store submission. Keep the installed direct bundle working as the
behavioral baseline while the sandbox path is incomplete.

## Locked outcome

- The Mac App Store is QuotaRoom's intended public release channel.
- The sellable product remains the 420-point, two-column complete-provider account room described by
  [PD-009 and PD-011](product-decisions.md).
- App Store work may replace provider acquisition mechanisms, but it does not silently remove Codex, Claude, Cursor,
  Grok, Antigravity, configured accounts, truthful errors, or the provider-colored aggregate chart.
- Distributed copies retain the upstream MIT license and copyright notice.

## Confirmed release gate

The current QuotaRoom application is not App Store ready. Its application entitlement file does not enable
`com.apple.security.app-sandbox`, and the installed bundle has no sandbox entitlement. The provider layer also reads
browser cookie/local-storage databases, local account homes, and installed command-line tools. Apple's Mac App Store
rules require an appropriately sandboxed, self-contained app packaged with Apple tooling.

This is an acquisition-boundary problem, not a listing-form problem. Creating the App Store Connect record first would
not prove that the submitted binary can still populate the product.

## Compatibility spike

1. Add a separate App Store packaging configuration with an App Store bundle identifier, App Sandbox, outbound network
   access, and no direct-distribution-only updater or login-item assumptions.
2. Inventory each shipped provider path and classify every required input as one of:
   - network API or provider-supported OAuth inside the sandbox;
   - user-selected folder retained with a security-scoped bookmark;
   - helper code embedded and signed inside the application bundle;
   - incompatible current mechanism that needs a provider-specific redesign.
3. Prove one sandboxed fixture account per provider, then the real complete account census, without temporary exception
   entitlements. A temporary exception is a documented last resort, not the product architecture.
4. Run the same installed-helper matrix and final Route B render used by the direct bundle. Any missing account or chart
   series fails the spike visibly.
5. Only after the provider matrix is green, create the App Store Connect app record and TestFlight build.

### Provider acquisition matrix

| Provider | Current working input | App Store path to prove | Status |
| --- | --- | --- | --- |
| Codex | Managed OAuth/web credentials, browser-session import or external Codex CLI fallback; ambient `~/.codex` session logs for the global chart | Keep managed credentials inside QuotaRoom; use the in-process authenticated HTTP path; let the user select each local history folder and retain a security-scoped bookmark | Prototype required |
| Claude | External `claude-swap` account list plus Claude config homes, CLI, OAuth, or browser web session | Replace `claude-swap` execution with an in-app account store and a reviewable in-process fetch path; verify that the chosen consumer-account API/auth mechanism is provider-supported | Provider/API decision required |
| Cursor | Browser cookie database or external `cursor-agent`, followed by Cursor web usage and cost endpoints | Obtain a provider-supported in-app authorization and usage mechanism; browser-database scraping and an external agent are not the release architecture | Provider/API blocker |
| Grok | Browser cookie import and a local Grok RPC/web-billing path | Obtain a provider-supported in-app authorization and subscription-usage mechanism; keep API-key billing separate from consumer quota | Provider/API blocker |
| Antigravity | Local Antigravity/`agy` process or the existing in-process remote OAuth fetcher | Make the existing remote OAuth fetcher the sandbox path and remove the external-process dependency | Best first prototype |

The matrix records confirmed current code paths and the smallest candidate sandbox boundary. “Provider/API blocker” means
the repository does not yet contain evidence of a supported replacement; it does not mean the provider is impossible.

## Storefront and review work after the spike

- Reserve the QuotaRoom name and final bundle identifier in Certificates, Identifiers & Profiles and App Store Connect.
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
