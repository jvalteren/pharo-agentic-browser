"
I represent errors that occur while preparing or checking crit review.

I carry a kind symbol identifying the error category and optional data for details.

Kinds:
- #invalidPortRange: AbSettings critPortRange cannot be parsed into a port interval
- #portRangeExhausted: every port in the interval is held by another topic's running crit
- #statusUnavailable: crit status did not report whether the daemon is running
"
Class {
	#name : 'AbCritError',
	#superclass : 'Error',
	#instVars : [
		'kind',
		'data'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'instance creation' }
AbCritError class >> kind: aKindSymbol [
	^ self new kind: aKindSymbol; yourself
]

{ #category : 'instance creation' }
AbCritError class >> kind: aKindSymbol data: aDictionary [
	^ self new kind: aKindSymbol; data: aDictionary; yourself
]

{ #category : 'instance creation' }
AbCritError class >> invalidPortRange: aMessage portRange: aRangeString [
	^ (self kind: #invalidPortRange)
		messageText: aMessage;
		dataAt: #portRange put: aRangeString;
		yourself
]

{ #category : 'instance creation' }
AbCritError class >> portRangeExhausted: aMessage portInterval: anInterval [
	^ (self kind: #portRangeExhausted)
		messageText: aMessage;
		dataAt: #portInterval put: anInterval;
		yourself
]

{ #category : 'instance creation' }
AbCritError class >> statusUnavailable: aMessage [
	^ (self kind: #statusUnavailable) messageText: aMessage; yourself
]

{ #category : 'accessing' }
AbCritError >> data [
	data ifNil: [ data := Dictionary new ].
	^ data
]

{ #category : 'accessing' }
AbCritError >> data: aDictionary [
	data := aDictionary
]

{ #category : 'accessing' }
AbCritError >> dataAt: key [
	^ self data at: key
]

{ #category : 'accessing' }
AbCritError >> dataAt: key put: value [
	self data at: key put: value
]

{ #category : 'accessing' }
AbCritError >> kind [
	^ kind
]

{ #category : 'accessing' }
AbCritError >> kind: aSymbol [
	kind := aSymbol
]
