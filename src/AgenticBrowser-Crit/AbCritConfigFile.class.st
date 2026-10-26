"
I am the .crit.config.json of one working directory.

Responsibility:
- I read and write the port, leaving every other key intact.
- I write the hooks AbCritReviewFinishResultsManager merges AgenticBrowser's crit finish hooks into, leaving other keys intact, and write nothing when it refuses or nothing changed.
- I treat a missing file, unreadable JSON, 0, or a port outside 1..65535 as unassigned.
- I own the built-in default document used when a directory has no readable config.
- On the class side I ensure a working directory has a port no running crit of another topic holds: I keep the configured port when it is free, and otherwise write the lowest free port in AbSettings default critPortInterval.

Collaborators:
- AbSettings: I read #critPortInterval when a port must be written.
- AbCritDaemon: It asks me for the port and the finish hooks just before spawning crit; I ask each other topic's daemon whether crit is running.
- AbCritReviewFinishResultsManager: I pass it my hooks and write back the hooks it answers with a topic's finish hooks added.
- AbTopicManager: my class-side topicManager supplies the topics whose ports may be in use.
- AbTopic: I read each topic's working directory and crit daemon when collecting ports in use.

Public API and Key Messages:
- AbCritConfigFile class>>in: - Config file for one directory.
- AbCritConfigFile class>>ensurePortIn: - Answer the port crit must use, among the topicManager's topics. Signals an AbCritError for an invalid range or an exhausted range.
- AbCritConfigFile class>>ensurePortIn:amongTopics: - Same, among the given topics.
- AbCritConfigFile class>>topicManager: - Inject the AbTopicManager to consult (defaults to AbTopicManager default).
- #port - Assigned port, or nil. Cached once read.
- #writePort: - Set port in the existing document, or in the built-in default when the file is missing or unreadable.
- #ensureFinishHooksFor: - Add a topic's finish hooks to hooks; answer false, writing nothing, when a user-defined finish hook is already there. Writes only when the hooks change, so crit's project trust stays valid.

Internal Representation:
- directory - FileReference of the working directory that contains .crit.config.json.
- port - Cached assigned port; nil until a valid port is read or written.
- topicManager (class inst var) - AbTopicManager whose topics are scanned for used ports; nil means AbTopicManager default.

Implementation Points:
- A port counts as used only when its topic's crit daemon reports running; a status error counts as not running.
- I do not serialize callers; AbCritDaemon holds its launch mutex around ensuring the port and spawning crit.
"
Class {
	#name : 'AbCritConfigFile',
	#superclass : 'Object',
	#instVars : [
		'directory',
		'port'
	],
	#classInstVars : [
		'topicManager'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'instance creation' }
AbCritConfigFile class >> in: aDirectoryReference [

	^ self new
		  directory: aDirectoryReference;
		  yourself
]

{ #category : 'accessing' }
AbCritConfigFile class >> fileName [

	^ '.crit.config.json'
]

{ #category : 'defaults' }
AbCritConfigFile class >> defaultContents [

	^ Dictionary new
		  at: 'port' put: 0;
		  at: 'no_open' put: true;
		  at: 'ignore_patterns' put: #( '.crit.config.json' );
		  yourself
]

{ #category : 'accessing' }
AbCritConfigFile class >> topicManager [

	^ topicManager ifNil: [ AbTopicManager default ]
]

{ #category : 'accessing' }
AbCritConfigFile class >> topicManager: anAbTopicManager [

	topicManager := anAbTopicManager
]

{ #category : 'port assignment' }
AbCritConfigFile class >> ensurePortIn: anAbWorkingDirectory [

	^ self
		  ensurePortIn: anAbWorkingDirectory
		  amongTopics: self topicManager topics
]

{ #category : 'port assignment' }
AbCritConfigFile class >> ensurePortIn: anAbWorkingDirectory amongTopics: aTopicCollection [

	| config used interval port |
	config := self in: anAbWorkingDirectory path.
	used := self portsOfRunningCritAmong: aTopicCollection excluding: anAbWorkingDirectory path.
	config port ifNotNil: [ :configured |
		(used includes: configured) ifFalse: [ ^ configured ] ].
	interval := AbSettings default critPortInterval ifNil: [
		^ (AbCritError
			   invalidPortRange: 'invalid critPortRange: ' , AbSettings default critPortRange asString
			   portRange: AbSettings default critPortRange) signal ].
	port := interval
		detect: [ :each | (used includes: each) not ]
		ifNone: [
			^ (AbCritError
				   portRangeExhausted: ('crit port range exhausted: {1}-{2}' format: { interval first. interval last })
				   portInterval: interval) signal ].
	config writePort: port.
	^ port
]

{ #category : 'private' }
AbCritConfigFile class >> portsOfRunningCritAmong: aTopicCollection excluding: aDirectoryReference [

	| excluded |
	excluded := aDirectoryReference fullName.
	^ aTopicCollection inject: Set new into: [ :used :topic |
		  | dir |
		  dir := topic workingDirectory path.
		  dir fullName = excluded ifFalse: [
			  (self in: dir) port ifNotNil: [ :port |
				  (self isCritRunningFor: topic) ifTrue: [ used add: port ] ] ].
		  used ]
]

{ #category : 'private' }
AbCritConfigFile class >> isCritRunningFor: anAbTopic [

	^ [ anAbTopic critDaemon isDaemonRunning ]
		  on: Error
		  do: [ false ]
]

{ #category : 'accessing' }
AbCritConfigFile >> directory [

	^ directory
]

{ #category : 'accessing' }
AbCritConfigFile >> directory: aDirectoryReference [

	directory := aDirectoryReference
]

{ #category : 'accessing' }
AbCritConfigFile >> file [

	^ self directory / self class fileName
]

{ #category : 'accessing' }
AbCritConfigFile >> port [

	^ port ifNil: [ port := self readPort ]
]

{ #category : 'private' }
AbCritConfigFile >> readPort [

	| raw |
	raw := [ (STONJSON fromString: self file contents) at: 'port' ifAbsent: [ nil ] ]
		       on: Error
		       do: [ nil ].
	(raw isInteger and: [ raw between: 1 and: 65535 ]) ifFalse: [ ^ nil ].
	^ raw
]

{ #category : 'operations' }
AbCritConfigFile >> writePort: anInteger [

	| contents |
	contents := self readContentsOrDefault.
	contents at: 'port' put: anInteger.
	self writeContents: contents.
	port := anInteger
]

{ #category : 'operations' }
AbCritConfigFile >> ensureFinishHooksFor: aTopic [

	| allConfigContents hooksDict |
	allConfigContents := self readContentsOrDefault.
	hooksDict := self reviewFinishResultsManager
		         finishHooksAttachedTo: (self hooksContentsIn: allConfigContents) for: aTopic.
	hooksDict ifNil: [ ^ false ].
	self applyHooks: hooksDict to: allConfigContents.
	^ true
]

{ #category : 'private' }
AbCritConfigFile >> hooksContentsIn: allConfigContents [

	^ allConfigContents at: 'hooks' ifAbsent: [ Dictionary new ]
]

{ #category : 'private' }
AbCritConfigFile >> applyHooks: aHookDictionary to: aContentsDictionary [
	"Write only when the hooks change, so crit's project trust stays valid."

	(aContentsDictionary at: 'hooks' ifAbsent: []) = aHookDictionary ifTrue: [ ^ self ].
	aContentsDictionary at: 'hooks' put: aHookDictionary.
	self writeContents: aContentsDictionary
]

{ #category : 'accessing' }
AbCritConfigFile >> reviewFinishResultsManager [

	^ AbCritReviewFinishResultsManager default
]

{ #category : 'private' }
AbCritConfigFile >> writeContents: aDictionary [

	self file safeWriteStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toStringPretty: aDictionary) ]
]

{ #category : 'private' }
AbCritConfigFile >> readContentsOrDefault [

	^ [ STONJSON fromString: self file contents ]
		  on: Error
		  do: [ self class defaultContents ]
]
