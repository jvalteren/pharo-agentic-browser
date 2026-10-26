"
I am the singleton registry and persistence manager for all AbTopic instances.

Responsibility:
- I maintain the collection of active topics keyed by their topicId.
- I persist topics to and load them from a Fuel binary file (ab-topics.fuel).
- I announce AbTopicAdded when a topic is registered.
- I announce AbTopicRemoved when a topic is removed.
- I clean up (stop watching, disconnect) topics on removal or image re-initialization.
- I provide topic lookup by topicId, working directory path, and name.
- I deliver the first crit review result after a review starts to its topic (#deliverCritFinishResults), as one of my periodic checks.
- I drop stale ACP client connections for all topics when the image resumes after a save/restart.
- I persist myself automatically whenever the image saves or quits, so topics survive a Pharo exit even if the AgenticBrowser window was never closed.
- I run a background process that periodically scans all topics for stalled ones and nudges them with a resume prompt, and delivers pending crit review results.
- I start watching for related-package changes across all my topics automatically. Both watching and monitoring start as soon as I am accessed (via #default or #load), independent of any UI (Pharo window, Web UI, or orchestration scripts) — watching a topic's packages is harmless even in a headless environment where no human edits will ever happen.

Collaborators:
- AbTopic: I own and lifecycle-manage all topic instances.
- AbTopicAdded: I announce it when a new topic is added.
- AbTopicRemoved: I announce it when a topic is removed.
- FLSerializer / FLMaterializer: I use the Fuel framework for binary serialization.
- AbCritReviewFinishResultsManager: I ask it to deliver pending crit review results to my topics; it looks them up with #at:.
- AbSettings: I read #monitoringIntervalSeconds through #settings.

Public API and Key Messages:
- AbTopicManager class>>#default - Access the global singleton.
- AbTopicManager class>>load / #save - Load from / save to ab-topics.fuel.
- #addTopic: - Register a topic and announce AbTopicAdded.
- #removeTopic: - Teardown, deregister, and announce AbTopicRemoved.
- #topics - All registered topics as an Array.
- #topicNamed: - Look up the first topic by name (lexicographic topicId order).
- #topicForWorkingDirectoryPath: - Look up a topic by its working directory path.
- #startMonitoring / #stopMonitoring - Start or stop the background monitoring process that runs the periodic topic checks.
- #resumeStalledTopics - Send each stalled topic's goal resume prompt once, synchronously.
- #deliverCritFinishResults - Have AbCritReviewFinishResultsManager deliver pending crit review results to my topics (see its #deliverResultsToTopicsIn:).

Internal Representation:
- topics - Dictionary keyed by topicId String, valued by AbTopic.
- announcer - Lazy Announcer; excluded from Fuel and recreated lazily after load.
- monitoringProcess - Background Process that runs #runMonitoringLoop; excluded from Fuel.
- default (class inst var) - The global singleton instance.
- forTest (class inst var) - Isolated instance used by the test suite; does not affect the global instance.
- announcer (class inst var) - Lazy Announcer for AbTopicManagerLoaded; class>>#announcer: lets tests swap in a private one.

Implementation Points:
- announcer is excluded from Fuel serialization; subscribers must re-subscribe after each load.
- #cleanupAllTopics stops watchers and disconnects agents; called before replacing the default instance on load, and on actual image quit (not a plain save) via class>>shutDown:.
- class>>initialize registers this class on Smalltalk's start-up and shut-down lists; class>>startUp: calls #resetStaleConnections on the default instance when the image resumes, so topics left open across a save/restart reconnect instead of writing to a dead subprocess's pipes.
- class>>shutDown: calls #save only when a default instance already exists in memory, to avoid lazily creating and persisting an empty manager when AgenticBrowser was never opened this session. It only tears down watchers/connections/monitoring when isImageQuitting is true; a plain image save (isImageQuitting false) leaves them running since the image keeps executing afterward. The quit teardown goes through #cleanupForImageQuit, which runs below the OSSubprocess child watcher's priority so the saved image never holds a half-finished watcher.
- #runMonitoringLoop sleeps for AbSettings>>#monitoringIntervalSeconds between ticks and runs each periodic check in turn (#resumeStalledTopics, then #deliverCritFinishResults). Each check swallows per-topic errors so one failing topic does not stop the rest from being checked.
- class>>default starts watching and monitoring the instant the singleton is lazily created; class>>defaultLoaded: (used by class>>load) starts both on the freshly loaded instance too, so any entry point that touches the default manager (Pharo UI, Web UI, orchestration scripts) gets them for free.
"
Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics',
		'announcer',
		'monitoringProcess'
	],
	#classInstVars : [
		'default',
		'forTest',
		'announcer'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManager class >> default [

	default ifNil: [
		default := self new.
		default startAllTopicsWatching.
		default startMonitoring ].
	^ default
]

{ #category : 'accessing-default' }
AbTopicManager class >> default: anInstance [

	default := anInstance
]

{ #category : 'accessing-default' }
AbTopicManager class >> defaultLoaded: anInstance [
	"Set anInstance as the default and announce AbTopicManagerLoaded so subscribers
	(e.g. AbTopicListPresenter) refresh against it. Use this instead of #default: whenever
	a UI may already be observing the previous default, such as restoring the original
	manager after a test swaps it out."

	default ifNotNil: [
		default cleanupAllTopics.
		default stopMonitoring ].
	self default: anInstance.
	anInstance ifNil: [ ^ self ].
	anInstance startAllTopicsWatching.
	anInstance startMonitoring.
	self announcer announce: (AbTopicManagerLoaded topicManager: anInstance)
]

{ #category : 'announcements' }
AbTopicManager class >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'announcements' }
AbTopicManager class >> announcer: anAnnouncer [
	"Test seam: lets a test swap in a private Announcer so its AbTopicManagerLoaded announcements do not reach live subscribers such as an open AbTopicListPresenter."

	announcer := anAnnouncer
]

{ #category : 'persistence' }
AbTopicManager class >> defaultFileReference [

	^ AbSettings defaultAgenticBrowserRootDirectory / self fileName
]

{ #category : 'persistence' }
AbTopicManager class >> fileName [

	^ 'ab-topics.fuel'
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest [

	^ forTest ifNil: [ forTest := self new ]
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest: anInstance [

	forTest := anInstance
]

{ #category : 'fuel' }
AbTopicManager class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' 'monitoringProcess' )
]

{ #category : 'class initialization' }
AbTopicManager class >> initialize [

	default ifNotNil: [
		default cleanupAllTopics.
		default stopMonitoring ].
	default := forTest := nil.
	Smalltalk addToStartUpList: self.
	Smalltalk addToShutDownList: self
]

{ #category : 'system startup' }
AbTopicManager class >> startUp: resuming [
	"Called by the session manager when the image resumes. If topics were left open across
	a Pharo image save/restart (not a Fuel reload), their ACP client still references the
	previous session's dead subprocess and pipes; drop those stale references so the next
	prompt reconnects and resumes the ACP session instead of writing to a closed pipe."

	resuming ifFalse: [ ^ self ].
	default ifNotNil: [
		default resetStaleConnections.
		default startAllTopicsWatching.
		default startMonitoring ]
]

{ #category : 'system startup' }
AbTopicManager class >> shutDown: isImageQuitting [
	"Called by the session manager whenever the image saves or quits, including when Pharo
	is closed without the AgenticBrowser window ever being closed. Only save if a default
	instance already exists in memory; otherwise this would lazily create an empty manager
	and overwrite whatever was previously persisted. The save is guarded so a serialization
	failure cannot abort the image save/quit. Watchers, agent connections, and stall
	monitoring are only torn down when the image is actually quitting (not on a plain save),
	since they should otherwise keep running regardless of whether any UI window is open."

	default ifNotNil: [ :defaultInstance |
		isImageQuitting ifTrue: [ defaultInstance cleanupForImageQuit ].
		[ defaultInstance save ]
			on: Error
			do: [ :e | "ignore; do not abort the image save/quit" ] ]
]

{ #category : 'persistence' }
AbTopicManager class >> load [

	| newDefault |
	self defaultFileReference exists ifFalse: [ ^ self ].
	default ifNotNil: [
		default cleanupAllTopics.
		default stopMonitoring ].
	newDefault := self loadFrom: self defaultFileReference.
	self defaultLoaded: newDefault
]

{ #category : 'persistence' }
AbTopicManager class >> loadFrom: aFileReference [

	^ FLMaterializer materializeFromFileNamed: aFileReference fullName
]

{ #category : 'persistence' }
AbTopicManager class >> save [

	self default save
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference [

	self default saveTo: aFileReference
]

{ #category : 'persistence' }
AbTopicManager >> save [

	self saveTo: self class defaultFileReference
]

{ #category : 'persistence' }
AbTopicManager >> saveTo: aFileReference [

	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: self toFileNamed: aFileReference fullName
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics at: anAbTopic topicId put: anAbTopic.
	self announcer announce: (AbTopicAdded topic: anAbTopic)
]

{ #category : 'accessing' }
AbTopicManager >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbTopicManager >> at: aTopicId [

	^ topics at: aTopicId ifAbsent: [ nil ]
]

{ #category : 'operations' }
AbTopicManager >> cleanupAllTopics [

	topics valuesDo: [ :topic | self teardownTopic: topic ]
]

{ #category : 'operations' }
AbTopicManager >> cleanupForImageQuit [
	"SessionManager runs shutDown: at timingPriority - 1, above the OSSubprocess child watcher
	(highIOPriority). Disconnecting agents there lets the agent's exit notification wake this
	process mid-#checkFinishedChildren, so the image is saved with the watcher suspended before
	it frees its ExternalAddress; on restart, terminating that watcher frees a stale address and
	fails. Running the cleanup below the watcher's priority lets the watcher finish first."

	| done |
	done := Semaphore new.
	[
	[
	self cleanupAllTopics.
	self stopMonitoring ] ensure: [ done signal ] ]
		forkAt: Processor userSchedulingPriority.
	done wait
]

{ #category : 'operations' }
AbTopicManager >> resetStaleConnections [
	"Drop each topic's ACP client without touching its watchers, so topics left open
	across an image restart reconnect fresh on the next prompt. Unlike #cleanupAllTopics,
	this does not stop related-packages watching, since the topics are still in active use."

	topics valuesDo: [ :topic |
		[ topic disconnect ]
			on: Error
			do: [ :e | topic logger warn: 'resetStaleConnections: disconnect failed - ' , e messageText ] ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := Dictionary new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	| removedTopic |
	self teardownTopic: anAbTopic.
	removedTopic := topics removeKey: anAbTopic topicId ifAbsent: [ ^ self ].
	self announcer announce: (AbTopicRemoved topic: removedTopic)
]

{ #category : 'operations' }
AbTopicManager >> startAllTopicsWatching [

	topics valuesDo: [ :t | t startWatching ]
]

{ #category : 'private' }
AbTopicManager >> teardownTopic: aTopic [

	aTopic stopWatching.
	[ aTopic disconnect ]
		on: Error
		do: [ :e | aTopic logger warn: 'teardownTopic: disconnect failed - ' , e messageText ]
]

{ #category : 'accessing' }
AbTopicManager >> topicForWorkingDirectoryPath: aString [

	| lookupPath |
	lookupPath := aString asFileReference fullName.
	^ topics values
		detect: [ :each |
			each workingDirectoryPath asFileReference fullName = lookupPath ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AbTopicManager >> topicNamed: aString [

	| matches |
	matches := self topicsNamed: aString.
	matches ifEmpty: [ ^ nil ].
	^ (matches asSortedCollection: [ :a :b | a topicId < b topicId ]) first
]

{ #category : 'accessing' }
AbTopicManager >> settings [

	^ AbSettings default
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics values asArray
]

{ #category : 'accessing' }
AbTopicManager >> topicsNamed: aString [

	^ topics values select: [ :each | each name = aString ]
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics valuesDo: aBlock
]

{ #category : 'operations' }
AbTopicManager >> stopAllTopicsWatching [

	topics valuesDo: [ :t | t stopWatching ]
]

{ #category : 'testing' }
AbTopicManager >> isMonitoring [

	^ monitoringProcess notNil and: [ monitoringProcess isTerminated not ]
]

{ #category : 'operations' }
AbTopicManager >> resumeStalledTopics [

	(self topics select: [ :t | t isStalled ]) do: [ :t |
		[ t sendPrompt: t topicGoal resumePrompt ]
			on: Error
			do: [ :e | t logger warn: 'resumeStalledTopics: sendPrompt: failed - ' , e messageText ] ]
]

{ #category : 'operations' }
AbTopicManager >> deliverCritFinishResults [

	self reviewFinishResultsManager deliverResultsToTopicsIn: self
]

{ #category : 'accessing' }
AbTopicManager >> reviewFinishResultsManager [

	^ AbCritReviewFinishResultsManager default
]

{ #category : 'private' }
AbTopicManager >> runMonitoringLoop [

	[ monitoringProcess notNil ] whileTrue: [
		(Delay forSeconds: self settings monitoringIntervalSeconds) wait.
		self resumeStalledTopics.
		self deliverCritFinishResults ]
]

{ #category : 'monitoring' }
AbTopicManager >> startMonitoring [

	self isMonitoring ifTrue: [ ^ self ].
	monitoringProcess := [ self runMonitoringLoop ] newProcess
		name: 'AgenticBrowser topics monitor';
		priority: Processor userBackgroundPriority;
		yourself.
	monitoringProcess resume
]

{ #category : 'monitoring' }
AbTopicManager >> stopMonitoring [

	monitoringProcess ifNotNil: [ :p | p terminate ].
	monitoringProcess := nil
]
