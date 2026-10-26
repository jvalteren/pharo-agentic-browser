Class {
	#name : 'AbStringShellQuotedTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbStringShellQuotedTest >> testShellQuotedWrapsInSingleQuotes [

	self assert: '/tmp/a b.log' shellQuoted equals: '''/tmp/a b.log'''
]

{ #category : 'tests' }
AbStringShellQuotedTest >> testShellQuotedEscapesEmbeddedSingleQuote [

	self assert: 'it''s' shellQuoted equals: '''it''\''''s'''
]
