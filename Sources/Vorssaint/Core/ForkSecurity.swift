// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Hardening switches for this fork. Each one turns off a mechanism whose
/// code stays in place, so a decision can be revisited by flipping a single
/// value. `docs/FORK-SECURITY.md` explains every switch.
enum ForkSecurity {
    /// Self-update checks GitHub Releases of the upstream repository and, for
    /// an app folder the user cannot write, installs the DMG as root. The
    /// installer pins the upstream Team ID, so a fork would either fail every
    /// install or replace itself with the official build.
    static let selfUpdateEnabled = false

    /// The fan-control helper is a root launch daemon that only trusts clients
    /// signed with the upstream Team ID; a fork build can never talk to it, and
    /// it is the most privileged component the app installs.
    static let fanControlEnabled = false

    /// The Codex and Claude Code usage checks run a `codex` or `claude` binary
    /// found in user-writable places (`~/.local/bin`, the shell PATH, version
    /// managers, any bundle registered with the Codex identifier) without a
    /// signature check, and the child inherits this app's privacy permissions.
    static let agentCLIProbesEnabled = false

    /// Temporary screenshot and recording links and in-app feedback go to
    /// `screenshots.vorssaint.com`, a server run by the upstream maintainer.
    /// A renamed fork has no business sending captures or reports there.
    static let cloudSharingEnabled = false
}
