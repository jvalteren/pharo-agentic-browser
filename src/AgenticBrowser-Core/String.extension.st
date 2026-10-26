Extension { #name : 'String' }

{ #category : '*AgenticBrowser-Core' }
String >> shellQuoted [
	"Answer me as one single-quoted POSIX shell word; each embedded single quote becomes '\''."

	^ String streamContents: [ :stream |
		  stream nextPut: $'.
		  self do: [ :char |
			  char = $'
				  ifTrue: [ stream nextPutAll: '''\''''' ]
				  ifFalse: [ stream nextPut: char ] ].
		  stream nextPut: $' ]
]
