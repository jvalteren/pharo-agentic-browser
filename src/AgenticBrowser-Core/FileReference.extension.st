Extension { #name : 'FileReference' }

{ #category : '*AgenticBrowser-Core' }
FileReference >> safeWriteStreamDo: aBlock [
	"Like #writeStreamDo:, but replaces an existing file completely (#writeStreamDo: does not truncate it).
	The old file is moved aside first and restored if aBlock fails.
	#moveTo: makes its receiver point to the new location, so it is sent to copies.
	Only Error is restored. A non-Error exception, such as TonelShouldIgnore, is left to propagate so it is not treated as a failed write."

	| backup result |
	self exists ifFalse: [ ^ self writeStreamDo: aBlock ].
	backup := self parent / (self basename , '.' , UUID new asString36 , '.bak').
	self copy moveTo: backup.
	result := [ self writeStreamDo: aBlock ]
		          on: Error
		          do: [ :ex |
			          self ensureDelete.
			          backup copy moveTo: self.
			          ex pass ].
	backup ensureDelete.
	^ result
]
