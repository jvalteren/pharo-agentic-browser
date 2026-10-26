# Feature: Configurable crit bind host (localhost-only option)

Kanban issue: `1791351639892-configurable-crit-bind-host-localhost-only-option`

## Goal

Operators who do not need LAN review can bind crit to localhost only, without
`--allow-unauthenticated-network` on `0.0.0.0`:

- New `AbSettings` key `critAllowUnauthenticatedNetwork` (Boolean, default `true` = current behavior).
- `true`: crit is spawned as today: `crit --no-open --host 0.0.0.0 --allow-unauthenticated-network`.
- `false`: crit is spawned with `--host 127.0.0.1` and without `--allow-unauthenticated-network`.
- The global settings dialog (`AbSettingsPresenter`) has a checkbox for the new key, saved like `useCrit`.
- The key round-trips through `ab-settings.json`; crit, settings and settings-presenter tests pass; changed files are lint clean.

Out of scope (per the issue's 対応案): changing the Web UI review URL. When bind is loopback, a review
started from a LAN Web UI client still gets a URL with the request host, which won't be reachable.
Tracked separately as `1792998718174-web-ui-crit-review-url-when-crit-is-bound-to-localhost-only`.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout, branch
`feature/configurable-crit-bind-host` created from `origin/develop`; agents do not commit).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Implement critAllowUnauthenticatedNetwork setting (TDD)'.
			t prompt: 'Add a setting that lets operators bind crit to localhost only. Work on the currently checked-out git branch only: do not switch branches, do not commit, do not push.

Verified context:
- AbCritDaemon>>spawn (src/AgenticBrowser-Crit/AbCritDaemon.class.st) currently runs: crit --no-open --host 0.0.0.0 --allow-unauthenticated-network >> <log> 2>&1 &
- Tests use AbStubCritDaemon (src/AgenticBrowser-Crit-Tests/AbStubCritDaemon.class.st), which records every command passed to #runShellCommand: in #executedCommands. AbCritDaemonTest>>spawnCount: counts commands beginning with ''crit --no-open''. Use that to assert the exact spawn command.
- AbSettings (src/AgenticBrowser-Core/AbSettings.class.st) already has useCrit / useCrit: (default false) and critPortRange / critPortRange: (stored via #at:put: / #at:ifAbsent: with a default method). Follow the same pattern. AbSettingsTest covers defaults, copy and ab-settings.json save/load round-trip for useCrit - add the same coverage for the new key.
- AbSettingsPresenter (src/AgenticBrowser-UI/AbSettingsPresenter.class.st) has useCritCheckbox: created in #initializePresenters, written back in #saveSettings (and in the other place that builds settings with critPortRange:), and added in #defaultLayout with withConstraints: [ :c | c height: 28 ]. Keep that pattern: a checkbox inside a height-constrained labeled row is invisible on Pharo 14. Tests are in src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st (see the useCrit tests, including the layout test that checks the checkbox is in layout allPresenters).

Requirements:
1. AbSettings: add critAllowUnauthenticatedNetwork / critAllowUnauthenticatedNetwork: (Boolean, default true, so existing behavior is unchanged), in the accessing category. Update the AbSettings CRC class comment line about crit to mention it.
2. AbCritDaemon>>spawn: when the setting is true, spawn exactly as now (crit --no-open --host 0.0.0.0 --allow-unauthenticated-network). When false, spawn with --host 127.0.0.1 and without --allow-unauthenticated-network. Read the setting from the same AbSettings source the crit code already uses (AbSettings default). Keep the change small, e.g. extract a method that answers the host/flag arguments with an intention-revealing name. Do not change reviewUrlForHost: or the Web UI.
3. AbSettingsPresenter: add a checkbox bound to critAllowUnauthenticatedNetwork with a clear label such as "Allow crit access from the network (unauthenticated)", reader accessor in the accessing category, written back wherever useCrit is written back, laid out right after the useCrit checkbox with the same height constraint. Enlarge initialExtent if needed so all rows stay visible. Update the CRC class comment.
4. Smallest change that satisfies the above; no unrelated refactors.

Follow strict TDD: first write failing tests (AbSettingsTest: default true, setter, copy, ab-settings.json round-trip without touching the real user settings file - reuse the existing approach in AbSettingsTest; AbCritDaemonTest: spawn command for true and for false, restoring AbSettings default afterwards the way the existing crit tests do; AbSettingsPresenterTest: checkbox shows the model value, save writes it, checkbox is in the layout). Import (st-import) and run them to see them fail, then implement, import and run until green. Run AbCritDaemonTest, AbSettingsTest and AbSettingsPresenterTest at the end.

When done, report which files you changed, the tests added, and the final test counts.'.
			t goal: 'critAllowUnauthenticatedNetwork (default true) controls the crit spawn host and flag, is editable in AbSettingsPresenter, and all tests in AbCritDaemonTest, AbSettingsTest and AbSettingsPresenterTest pass' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run crit and settings test suites and report'.
			t prompt: 'Using the st-test skill (or the run_class_test / run_package_test MCP tools), run AbCritDaemonTest, AbSettingsTest and AbSettingsPresenterTest, then the whole AgenticBrowser-Crit-Tests and AgenticBrowser-Tests packages, and AbTopicManagerRippleTest in AgenticBrowser-WebUI-Tests. Report exact pass/fail/error counts per class/package and the full text of any failure or error, quoting the failing test name and message. Do not fix anything in this step and do not commit or push - just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the Tonel files changed for the critAllowUnauthenticatedNetwork feature (check git diff on the current branch; expect AbSettings, AbCritDaemon, AbSettingsPresenter and their test classes). Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) for each changed file, and consult the smalltalk-developer skill style guide section. Check that class/method/variable names are intention revealing, that the spawn command logic is not duplicated (DRY), that all accessors are in the accessing category, that the default (true) keeps the previous spawn command byte-for-byte, and that the CRC class comments mention the new setting and checkbox. Fix anything flagged, re-import, and re-run AbCritDaemonTest, AbSettingsTest and AbSettingsPresenterTest to confirm they still pass. Do not commit or push. Report what you found and fixed, or confirm the files were already clean.' ]
	} agentBy: [ :a | a claude ] ].
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ]
	onTimeout: [ :timeoutStep :ex | Transcript crShow: 'Timed out: ' , timeoutStep printString ].
script register
```

## How to run

Paste the script above into a Pharo Playground, or ask the assistant to run it via st-eval.
`forkRunThen:onTimeout:` runs the orchestration in the background and returns immediately — watch
for the completion block's own report (e.g. via Transcript), the `onTimeout:` block's report if a
step stalls, or check progress with `AbOrchestrationManager default orchestrationAt: <orchestration script id>`.
