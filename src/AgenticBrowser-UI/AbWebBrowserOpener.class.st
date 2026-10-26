"
I open a URL in the user's default web browser.

Responsibility:
- On Linux, launch `xdg-open` with `LD_LIBRARY_PATH` removed, because the Pharo VM sets it to its bundled libraries (e.g. an old libharfbuzz), which breaks browsers such as Chrome that load newer system libraries.
- On other platforms, delegate to `WebBrowser openOn:`.

Collaborators:
- `WebBrowser` for non-Linux platforms
- `LibC` to run the shell command on Linux

Example:
	AbWebBrowserOpener open: 'https://pharo.org'
"
Class {
	#name : 'AbWebBrowserOpener',
	#superclass : 'Object',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'actions' }
AbWebBrowserOpener class >> open: urlString [

	^ self new open: urlString
]

{ #category : 'private' }
AbWebBrowserOpener >> linuxOpenCommandFor: urlString [

	^ 'env -u LD_LIBRARY_PATH xdg-open {1} &' format: { urlString shellQuoted }
]

{ #category : 'actions' }
AbWebBrowserOpener >> open: urlString [

	OSPlatform current isLinux ifFalse: [ ^ WebBrowser openOn: urlString ].
	LibC system: (self linuxOpenCommandFor: urlString)
]
