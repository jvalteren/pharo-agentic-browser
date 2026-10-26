Class {
	#name : 'AbFileReferenceSafeWriteTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'root'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbFileReferenceSafeWriteTest >> setUp [

	super setUp.
	root := FileLocator temp / ('ab-safe-write-' , UUID new asString36).
	root ensureCreateDirectory
]

{ #category : 'running' }
AbFileReferenceSafeWriteTest >> tearDown [

	root exists ifTrue: [ root deleteAll ].
	super tearDown
]

{ #category : 'tests' }
AbFileReferenceSafeWriteTest >> testSafeWriteReplacesLongerContentsCompletely [

	| file |
	file := root / 'a.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: '0123456789' ].
	file safeWriteStreamDo: [ :stream | stream nextPutAll: 'ab' ].
	self assert: file contents equals: 'ab'.
	self assert: root children size equals: 1
]

{ #category : 'tests' }
AbFileReferenceSafeWriteTest >> testSafeWriteCreatesMissingFile [

	| file |
	file := root / 'new.json'.
	file safeWriteStreamDo: [ :stream | stream nextPutAll: 'new' ].
	self assert: file contents equals: 'new'
]

{ #category : 'tests' }
AbFileReferenceSafeWriteTest >> testSafeWriteRestoresOriginalWhenWritingFails [

	| file |
	file := root / 'a.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'original' ].
	self
		should: [
			file safeWriteStreamDo: [ :stream |
				stream nextPutAll: 'partial'.
				self error: 'write failed' ] ]
		raise: Error.
	self assert: file contents equals: 'original'.
	self assert: root children size equals: 1
]
