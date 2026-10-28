# SPDX-License-Identifier: GPL-3.0-only
"""Legacy live-debugger entry point, disabled after the MetalFX/GPU incident.

An 11-second live attach coincided with GPU timeouts and a subsequent MetalFX
abort. Native checks now use local.mactrainer.re2 unified logging. This module
performs no target lookup, memory read, expression evaluation, attach or launch.
"""


def snapshot(debugger, evidence_path, output_path):
    raise RuntimeError('Live LLDB snapshots disabled after the MetalFX/GPU-timeout incident. Use local.mactrainer.re2 unified logging without pausing the game.')
