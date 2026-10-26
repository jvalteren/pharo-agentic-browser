Class {
	#name : 'AbCritReviewFinishResultTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Crit-Tests',
	#package : 'AgenticBrowser-Crit-Tests'
}

{ #category : 'test data' }
AbCritReviewFinishResultTest >> round1UnresolvedPayload [
	"Recorded from crit v0.21.0 on 2026-10-16."

	^ '{"approved":false,"comments_all_cmd":"crit comments --json --all /home/mumez/.crit/reviews/47d359cc3b15","comments_cmd":"crit comments --json /home/mumez/.crit/reviews/47d359cc3b15","comments_json":[{"scope":"line","path":"a.txt","id":"c_db62fc","start_line":2,"end_line":2,"body":"round1: why changed?","anchor":"line2 changed","author":"Reviewer","created_at":"2026-10-16T08:03:51Z","updated_at":"2026-10-16T08:03:51Z"}],"comments_unresolved_json":[{"scope":"line","path":"a.txt","id":"c_db62fc","start_line":2,"end_line":2,"body":"round1: why changed?","anchor":"line2 changed","author":"Reviewer","created_at":"2026-10-16T08:03:51Z","updated_at":"2026-10-16T08:03:51Z"}],"files_with_comments":["a.txt"],"internal_session_mode":"git","mode":"diff","next_round_cmd":"crit --session 47d359cc3b15","plan_slug":"","review_path":"/home/mumez/.crit/reviews/47d359cc3b15","session_key":"47d359cc3b15","session_stats":{"comments_submitted":0,"duration_seconds":71,"files_reviewed":1},"total_count":1,"unresolved_count":1}'
]

{ #category : 'test data' }
AbCritReviewFinishResultTest >> round2UnresolvedPayload [
	"Recorded from crit v0.21.0 on 2026-10-16."

	^ '{"approved":false,"comments_all_cmd":"crit comments --json --all /home/mumez/.crit/reviews/47d359cc3b15","comments_cmd":"crit comments --json /home/mumez/.crit/reviews/47d359cc3b15","comments_json":[{"scope":"line","path":"a.txt","id":"c_db62fc","start_line":2,"end_line":2,"body":"round1: why changed?","anchor":"line2 changed","author":"Reviewer","created_at":"2026-10-16T08:03:51Z","updated_at":"2026-10-16T08:03:51Z","replies":[{"id":"rp_f87f3a","body":"Changed line2 for the test.","author":"agent","created_at":"2026-10-16T08:05:33Z","review_round":1}]},{"scope":"line","path":"a.txt","id":"c_adc9df","start_line":4,"end_line":4,"body":"round2: why line4?","anchor":"line4","author":"Reviewer","created_at":"2026-10-16T08:05:34Z","updated_at":"2026-10-16T08:05:34Z"}],"comments_unresolved_json":[{"scope":"line","path":"a.txt","id":"c_db62fc","start_line":2,"end_line":2,"body":"round1: why changed?","anchor":"line2 changed","author":"Reviewer","created_at":"2026-10-16T08:03:51Z","updated_at":"2026-10-16T08:03:51Z","replies":[{"id":"rp_f87f3a","body":"Changed line2 for the test.","author":"agent","created_at":"2026-10-16T08:05:33Z","review_round":1}]},{"scope":"line","path":"a.txt","id":"c_adc9df","start_line":4,"end_line":4,"body":"round2: why line4?","anchor":"line4","author":"Reviewer","created_at":"2026-10-16T08:05:34Z","updated_at":"2026-10-16T08:05:34Z"}],"files_with_comments":["a.txt"],"internal_session_mode":"git","mode":"diff","next_round_cmd":"crit --session 47d359cc3b15","plan_slug":"","review_path":"/home/mumez/.crit/reviews/47d359cc3b15","session_key":"47d359cc3b15","session_stats":{"comments_submitted":0,"duration_seconds":117,"files_reviewed":1},"total_count":2,"unresolved_count":2}'
]

{ #category : 'test data' }
AbCritReviewFinishResultTest >> approvedPayload [
	"Recorded from crit v0.21.0 on 2026-10-16."

	^ '{"approved":true,"comments_all_cmd":"crit comments --json --all /home/mumez/.crit/reviews/47d359cc3b15","comments_cmd":"crit comments --json /home/mumez/.crit/reviews/47d359cc3b15","comments_json":[{"scope":"line","path":"a.txt","id":"c_db62fc","start_line":2,"end_line":2,"body":"round1: why changed?","anchor":"line2 changed","author":"Reviewer","created_at":"2026-10-16T08:03:51Z","updated_at":"2026-10-16T08:36:25Z","resolved":true,"resolved_round":3,"carried_forward":true,"replies":[{"id":"rp_f87f3a","body":"Changed line2 for the test.","author":"agent","created_at":"2026-10-16T08:05:33Z","review_round":1}]},{"scope":"line","path":"a.txt","id":"c_e4a4f2","start_line":3,"end_line":3,"body":"test","anchor":"line3","author":"Masashi Umezawa","created_at":"2026-10-16T08:13:36Z","updated_at":"2026-10-16T08:36:27Z","resolved":true,"resolved_round":3,"carried_forward":true,"review_round":2},{"scope":"line","path":"a.txt","id":"c_adc9df","start_line":4,"end_line":4,"body":"round2: why line4?","anchor":"line4","author":"Reviewer","created_at":"2026-10-16T08:05:34Z","updated_at":"2026-10-16T08:36:28Z","resolved":true,"resolved_round":3,"carried_forward":true}],"comments_unresolved_json":[],"files_with_comments":null,"internal_session_mode":"git","mode":"diff","next_round_cmd":"crit --session 47d359cc3b15","plan_slug":"","review_path":"/home/mumez/.crit/reviews/47d359cc3b15","session_key":"47d359cc3b15","session_stats":{"comments_submitted":1,"duration_seconds":1817,"files_reviewed":1},"total_count":3,"unresolved_count":0}'
]

{ #category : 'private' }
AbCritReviewFinishResultTest >> resultOfKind: aKindSymbol containing: aString [

	| file |
	file := FileSystem memory root / 'result.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ].
	^ AbCritReviewFinishResult file: file topicId: 't' kind: aKindSymbol
]

{ #category : 'tests' }
AbCritReviewFinishResultTest >> testIsApprovedOnlyForApprovedKind [

	self deny: (self resultOfKind: #unresolved containing: self round1UnresolvedPayload) isApproved.
	self assert: (self resultOfKind: #approved containing: self approvedPayload) isApproved
]

{ #category : 'tests' }
AbCritReviewFinishResultTest >> testPayloadIsParsedJson [

	| payload |
	payload := (self resultOfKind: #unresolved containing: self round1UnresolvedPayload) payload.
	self assert: (payload at: 'unresolved_count') equals: 1.
	self assert: (payload at: 'next_round_cmd') equals: 'crit --session 47d359cc3b15'
]

{ #category : 'tests' }
AbCritReviewFinishResultTest >> testPayloadOfBrokenJsonSignalsError [

	self
		should: [ (self resultOfKind: #unresolved containing: '{"approved": fal') payload ]
		raise: Error
]

{ #category : 'tests' }
AbCritReviewFinishResultTest >> testPromptListsUnresolvedCommentsAndHandsOverTheLoop [

	| prompt |
	prompt := (self resultOfKind: #unresolved containing: self round1UnresolvedPayload) prompt.
	self assert: (prompt beginsWith: 'The review finished with 1 unresolved comment.').
	self assert: (prompt includesSubstring: 'c_db62fc').
	self assert: (prompt includesSubstring: 'round1: why changed?').
	self assert: (prompt includesSubstring: '`crit comment --reply-to <comment-id> --author <your-name> "<explanation>"`').
	self assert: (prompt endsWith: 'When you''re done, run:' , String lf , String lf , '  crit --session 47d359cc3b15')
]

{ #category : 'tests' }
AbCritReviewFinishResultTest >> testPromptKeepsEarlierRepliesAndCountsPlural [

	| prompt |
	prompt := (self resultOfKind: #unresolved containing: self round2UnresolvedPayload) prompt.
	self assert: (prompt beginsWith: 'The review finished with 2 unresolved comments.').
	self assert: (prompt includesSubstring: 'c_adc9df').
	self assert: (prompt includesSubstring: 'Changed line2 for the test.')
]

