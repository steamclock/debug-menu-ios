# CLAUDE.md

Project conventions for this repository. These are **mandatory rules**, not suggestions —
`review-code-style` treats any rule here phrased as MUST / always / never as a 🔴 blocker when a
diff violates it. Keep this file prescriptive and true; a vague or stale rule produces noisy false
blockers.

> This file holds general project guidance for everyone working in the repo. Project *kit* config
> (the repo identifier, platform globs, release settings) lives in `AGENTS.md`, not here.

---

## Evidence Over Speculation

**Every change MUST fix a problem that has been observed or implement an explicit requirement.**
Observed means a failing run, a measured behaviour, a reproduced bug, or a failure mode the code
path you are touching is known to have (an endpoint that returns 401 on bad credentials, a network
call that can time out). Explicit means the ticket, its acceptance criteria, or a convention in this
file asks for it.

What this rules out is the guard, fallback, retry, or standing infrastructure for a problem nobody
has seen and nothing requires: a retry wrapper around a call that has never failed, a cache in front
of a lookup nobody measured as slow, a default in-memory store that stands in when the real one is
not configured, a `try/catch` that papers over an error path with no known trigger. Leave these out
**even when a plan or a review proposes them.** If a safeguard still seems worth having, it becomes
its own ticket with the evidence attached, not an inline addition to the current one.

What it does not rule out is handling the failure modes that are part of the contract of the thing
you are building. A sign-in form showing the server's error on wrong credentials, a network layer
surfacing a timeout to its caller, a parser rejecting the malformed input it is specified to reject:
these are requirements of the feature whether or not the ticket spells them out, and the "never
swallow errors silently" rule below expects them. The test is whether you can point at the evidence
or the requirement. If the honest answer is "it might happen someday," it is speculation.

---

## Code Quality

These apply regardless of language.

- **Delete dead code** rather than commenting it out. Version control is the history.
- **No magic numbers or strings** — use named constants, enums, or localization/config keys.
- **Keep functions short and single-purpose.** Aim for under ~50 lines; if a function needs a
  comment to explain *what* it does (rather than *why*), or you can't hold it in your head, split it.
- **Keep files focused.** Aim for under ~500 lines per file. A file that's much larger is usually
  several concerns wearing one filename — split it along a real boundary. Treat this as a target,
  not a hard gate: a file a little over the line isn't a review blocker.
- **Modular boundaries.** Group code into modules with clear responsibilities and minimal
  cross-talk, so a change to one concern doesn't ripple through unrelated files.
- **Names read as intent.** No abbreviations where a full word is clear (`sightingCount`, not
  `sightCnt`). Booleans read as assertions (`isLoading`, `hasResults`, `canRetry`).
- **Never swallow errors silently** — at minimum log them; prefer surfacing them to the caller.
- **Log with structure and context.** Prefer structured logs carrying the relevant identifiers and
  state over bare strings, so a failure records *what* failed and *why*, not just `"error"`.
- **Minimize visibility.** Expose only what is part of a type's or module's public interface.
## Swift Package Conventions

This repo is a Swift package (the `DebugMenu` library) plus an example app that exercises it. The
rules below apply to the library. The example app follows them too, but exists to demonstrate the
public API, so keep it simple.

### Platform and Language

- The package targets **iOS 15+** and builds in **Swift 6 language mode** with strict concurrency.
- There is one version of the package. Use `if #available` only where a newer API is a contained
  win in one place (e.g. `NavigationStack` for submenus). Never fork a whole type or feature by OS
  version.
- Never use `@unchecked Sendable` or `nonisolated(unsafe)` without a comment that cites the ticket
  and explains why the compiler can't prove safety.

### Public API

- **Minimize visibility.** Types and members are `internal` by default; mark `public` only what a
  consuming app needs. Every `public` declaration is API surface we have to keep stable.
- Every `public` declaration has a `///` doc comment.

### Observation and State

- The menu never owns app values. Rows read and write through `get`/`set` closures into the app's
  own state.
- Keep the library's own observable state minimal (e.g. a refresh signal, the unlock flag). Use
  `ObservableObject` for it, since `@Observable` needs iOS 17.
- Never give a row its own Combine publisher.
- Observable state types that drive UI are `@MainActor`.

### Swift Code Quality

**Naming**
- Types: `UpperCamelCase`. Functions and properties: `lowerCamelCase`.
- Boolean properties and parameters read as assertions: `isEnabled`, `hasPassword`, `canReset`.

**Types and Safety**
- Prefer `struct` over `class` unless reference semantics are required.
- Use `enum` with associated values instead of parallel optional properties.
- Never force-unwrap (`!`) except in tests. Use `guard let` / `if let` / `??`.
- Avoid `try!` and `fatalError` outside truly unrecoverable conditions.
- Prefer typed errors (`enum MyError: Error`) over stringly-typed messages.

**SwiftUI Patterns**
- Break large view bodies into smaller `private var` computed properties or private sub-views, not
  helper functions that return `some View`.
- Inject dependencies into views via the initializer or environment. No singletons accessed
  directly from view bodies.
- Use `.task {}` for async work tied to a view's lifetime.
- Use `NavigationView` for navigation, with `NavigationStack` behind `if #available(iOS 16, *)`
  where it's a contained swap.

**Async / Concurrency**
- Use Swift Concurrency (`async/await`, `Task`, actors). No Combine beyond what `ObservableObject`
  needs.

**Error Handling**
- Do not swallow errors silently. At minimum log them; prefer surfacing them to the caller.

**Testing**
- Test observable outputs given inputs, not private implementation details.
