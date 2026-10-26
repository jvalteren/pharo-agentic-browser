# Feature: Settings UI for useCrit and critPortRange

Kanban issue: `1791351639335-settings-ui-for-usecrit-and-critportrange`

## Goal

Operators can turn crit review on and edit the crit port range from the Spec settings dialog
(`AbSettingsPresenter`), without editing `ab-settings.json` or evaluating accessors:

- The global settings dialog can set and save both `useCrit` and `critPortRange`.
- An invalid `critPortRange` is not saved; the dialog stays open and shows validation feedback
  (no silent fallback to a random port).
- Round-trip through `ab-settings.json` still works for both keys.
- `AbSettingsPresenterTest` and `AbSettingsTest` pass; changed files are lint clean.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout, branch
`feature/settings-ui-for-usecrit-and-critportrange` already checked out).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Implement crit settings in AbSettingsPresenter (TDD)'.
			t prompt: 'Add UI for the existing crit settings to the Spec settings dialog AbSettingsPresenter (src/AgenticBrowser-UI/AbSettingsPresenter.class.st) so operators can turn crit review on and edit the crit port range without editing ab-settings.json. Work on the currently checked-out git branch only: do not switch branches, do not commit, do not push.

Verified context:
- AbSettings (src/AgenticBrowser-Core/AbSettings.class.st) already has accessors useCrit / useCrit: (default false) and critPortRange / critPortRange: (default 9080-9100 as a String), plus critPortInterval, which answers nil for a malformed or out-of-bounds range string (see AbSettingsTest>>testCritPortIntervalRejectsMalformedOrOutOfBoundsRanges). Persistence is ab-settings.json via AbSettings class>>save / load. Do not change AbSettings unless strictly needed.
- AbSettingsPresenter builds widgets by hand in #initializePresenters, writes back in #saveSettings, and lays out in #defaultLayout. Checkboxes are added directly with withConstraints: [ :c | c height: 28 ] - keep that pattern (a checkbox inside a height-constrained labeled row is invisible on Pharo 14). Text fields use #labeledRow:field:.
- Tests live in src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st; follow its existing style.

Requirements:
1. Add a checkbox labeled "Use crit review" bound to useCrit and a text field shown with the label "Crit port range:" bound to critPortRange, both initialized from the model, with reader accessors in the accessing category, following the existing field/checkbox naming patterns (e.g. useCritCheckbox, critPortRangeField).
2. #saveSettings writes both keys back to the settings model.
3. Validation: an invalid critPortRange (one for which AbSettings>>critPortInterval would answer nil) must NOT be written to the settings and saveAction must NOT be called; the Save button must keep the dialog open and show visible validation feedback inside the dialog (e.g. a validation message label that is empty normally and explains the expected format such as 9080-9100 when invalid). Reuse the AbSettings>>critPortInterval logic for the check instead of duplicating the regex (DRY) - for example validate against a scratch AbSettings or extract a class-side/shared parsing helper used by both, whichever is the smallest clean change. Valid input saves and closes the dialog as before.
4. Round-trip: make sure both keys survive a save/load through ab-settings.json. Add a test for it if one does not already exist, without touching the real user settings file (look at how AbSettingsTest handles save/load and file locations, and reuse that approach).
5. Update the CRC class comment of AbSettingsPresenter to mention the new fields and the validation behavior; also fix the comment line that says the global path writes "the fuel file" - it is ab-settings.json.
6. Enlarge the window initialExtent if needed so all rows remain visible.
7. Smallest change that satisfies the above; no unrelated refactors.

Follow strict TDD: first write failing tests in AbSettingsPresenterTest (checkbox and field show default values; save writes useCrit and critPortRange; invalid range is not saved, feedback is shown, saveAction is not called; valid range clears feedback), import and run them to see them fail, then implement, import (st-import) and run until green. Run AbSettingsPresenterTest and AbSettingsTest at the end.

When done, report which files you changed, the tests added, and the final test counts.'.
			t goal: 'AbSettingsPresenter shows and saves useCrit and critPortRange with validation feedback for invalid ranges, and all tests in AbSettingsPresenterTest and AbSettingsTest pass' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run settings-related test suites and report'.
			t prompt: 'Using the st-test skill (or the run_class_test / run_package_test MCP tools), run AbSettingsPresenterTest and AbSettingsTest, then the whole AgenticBrowser-Tests package. Report exact pass/fail/error counts per class/package and the full text of any failure or error, quoting the failing test name and message. Do not fix anything in this step and do not commit or push - just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the Tonel files changed for the crit settings UI feature (check git diff on the current branch; expect at least src/AgenticBrowser-UI/AbSettingsPresenter.class.st and src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st). Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) for each changed file, and consult the smalltalk-developer skill style guide section. Check that class/method/variable names are intention revealing, that the port range validation does not duplicate the AbSettings>>critPortInterval parsing logic (DRY), that all accessors are in the accessing category, and that the CRC class comment lists the new fields. Fix anything flagged, re-import, and re-run AbSettingsPresenterTest and AbSettingsTest to confirm they still pass. Do not commit or push. Report what you found and fixed, or confirm the files were already clean.' ]
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
