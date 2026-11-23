"
PHARO-LOG-5: Go cleanRecord patterns applied to a fixed point within eight passes. Escapes and encodes one LF-terminated record, withholding failures and records over 64 KiB. Object is the service or value boundary.

  PuntLogRedactor new class name
  >>> #PuntLogRedactor
"
Class {
	#name : 'PuntLogRedactor',
	#superclass : 'Object',
	#instVars : [
		'home'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'private' }
PuntLogRedactor >> authPattern [ ^ self expand: '(\b(bearer|basic)([\s<VT><NEL>]+|\\(t|x09|x20))+)(\[redacted\]|["'']?[a-z0-9._~+/%=-]+["'']?)'
]

{ #category : 'private' }
PuntLogRedactor >> canMatch: name in: text [
 (#(userInfo email) includes: name) ifTrue: [ ^ text includes: $@ ].
 name = #url ifTrue: [ ^ text includesSubstring: '://' ].
 name = #cookie ifTrue: [ ^ text asLowercase includesSubstring: 'cookie' ].
 name = #keyValue ifTrue: [ ^ self hasCredentialKey: text ].
 name = #auth ifTrue: [ ^ (text asLowercase includesSubstring: 'bearer') or: [ text asLowercase includesSubstring: 'basic' ] ].
 ^ (text asLowercase includesSubstring: 'gh') or: [ text asLowercase includesSubstring: 'sk-' ]
]

{ #category : 'private' }
PuntLogRedactor >> clean: aString [
 | text masked bytes |
 (aString isEmpty or: [ (self validUnicode: aString) not or: [ aString utf8Encoded size >= 65536 ] ]) ifTrue: [ ^ nil ].
 text := aString.
 8 timesRepeat: [
   masked := self mask: text.
   masked = text ifTrue: [
     bytes := ((PuntEscaper escape: masked) , String lf) utf8Encoded.
     ^ bytes size <= 65536 ifTrue: [ bytes ] ifFalse: [ nil ] ].
   text := masked ].
 ^ nil
]

{ #category : 'redacting' }
PuntLogRedactor >> cleanEscapedRecord: aString [
 ^ [ self cleanRecord: (self restoreSpacing: aString) ] on: Error do: [ :error | nil ]
]

{ #category : 'redacting' }
PuntLogRedactor >> cleanRecord: aString [
 ^ [ self clean: aString ] on: Error do: [ :error | nil ]
]

{ #category : 'private' }
PuntLogRedactor >> cookiePattern [ ^ self expand: '(\b(set-cookie|cookie)\:[ <TAB>]*)[^<CR><LF>]*'
]

{ #category : 'private' }
PuntLogRedactor >> emailPattern [ ^ self expand: '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}'
]

{ #category : 'private' }
PuntLogRedactor >> escapedCode: code [
 ^ String streamContents: [ :stream |
   stream nextPutAll: '\x'; nextPutAll: ((code printStringBase: 16) asLowercase padLeftTo: 2 with: $0) ]
]

{ #category : 'private' }
PuntLogRedactor >> expand: text [
 | expanded |
 expanded := text.
 { '<TAB>' -> 9. '<LF>' -> 10. '<VT>' -> 11. '<CR>' -> 13. '<NEL>' -> 133. '<LS>' -> 8232. '<PS>' -> 8233 } do: [ :pair |
   expanded := expanded copyReplaceAll: pair key with: (Character value: pair value) asString ].
 ^ expanded
]

{ #category : 'private' }
PuntLogRedactor >> hasCredentialKey: text [
 | lower |
 lower := text asLowercase.
 ^ #('authorization' 'token' 'key' 'password' 'passwd' 'secret' 'credential' 'cookie') anySatisfy: [ :word | lower includesSubstring: word ]
]

{ #category : 'initialization' }
PuntLogRedactor >> home: aString [ home := aString
]

{ #category : 'private' }
PuntLogRedactor >> keyShapePattern [ ^ self expand: '\b(gh[pousr]_[a-z0-9]{16,}|github_pat_[a-z0-9_]{16,}|sk-[a-z0-9_-]{16,})\b'
]

{ #category : 'private' }
PuntLogRedactor >> keyValuePattern [ ^ self expand: '(\b([a-z0-9]+[-_])?([a-z0-9]+[-_])?([a-z0-9]+[-_])?([a-z0-9]+[-_])?([a-z0-9]+[-_])?(authorization|((api|access|refresh|session)[-_]?)?token|api[-_]?key|password|passwd|secret|credentials?|cookie)\b["'']?\s*[:=]\s*)(\[redacted\]|"[^"<CR><LF>]*"|''[^''<CR><LF>]*''|(basic|bearer)\s+[^\s,;]+|[^\s,;]+)'
]

{ #category : 'private' }
PuntLogRedactor >> mask: text [
 | masked |
 masked := self maskCredentials: text.
 (home notNil and: [ home notEmpty and: [ home ~= '/' ] ]) ifTrue: [ masked := masked copyReplaceAll: home with: '~' ].
 masked := (masked includes: $/) ifTrue: [ self replace: masked pattern: self pathPattern with: '[path]' prefix: true ] ifFalse: [ masked ].
 ^ self opaque: masked
]

{ #category : 'private' }
PuntLogRedactor >> maskCredentials: text [
 | masked |
 masked := text.
 #(url cookie keyValue auth keyShape userInfo email) do: [ :name |
   masked := self performMask: name on: masked ].
 ^ masked
]

{ #category : 'private' }
PuntLogRedactor >> opaque: text [
 | cursor start |
 cursor := 1.
 ^ String streamContents: [ :stream |
   [ cursor <= text size ] whileTrue: [
     (self tokenSeparator: (text at: cursor))
       ifTrue: [ stream nextPut: (text at: cursor). cursor := cursor + 1 ]
       ifFalse: [
         start := cursor.
         [ cursor <= text size and: [ (self tokenSeparator: (text at: cursor)) not ] ] whileTrue: [ cursor := cursor + 1 ].
         self token: (text copyFrom: start to: cursor - 1) on: stream ] ] ]
]

{ #category : 'private' }
PuntLogRedactor >> pathPattern [ ^ self expand: '(^|[\s=(:"''])(/|~/)[^\s"''<>]+'
]

{ #category : 'private' }
PuntLogRedactor >> patterns [
 ^ { #url -> self urlPattern. #cookie -> self cookiePattern. #keyValue -> self keyValuePattern.
     #auth -> self authPattern. #keyShape -> self keyShapePattern. #userInfo -> self userInfoPattern.
     #email -> self emailPattern } asDictionary
]

{ #category : 'private' }
PuntLogRedactor >> performMask: aName on: text [
 | prefix replacement |
 (self canMatch: aName in: text) ifFalse: [ ^ text ].
 prefix := #(cookie keyValue auth) includes: aName.
 replacement := (#(url userInfo email) includes: aName)
   ifTrue: [ aName = #userInfo ifTrue: [ '[userinfo]' ] ifFalse: [ '[' , aName , ']' ] ]
   ifFalse: [ '[redacted]' ].
 ^ self replace: text pattern: (self patterns at: aName) with: replacement prefix: prefix
]

{ #category : 'private' }
PuntLogRedactor >> replace: text pattern: pattern with: replacement prefix: keepPrefix [
 | matcher |
 matcher := PuntLogRegexMatcher forString: pattern ignoreCase: true.
 ^ matcher copy: text translatingMatchesUsing: [ :match |
   keepPrefix ifTrue: [ (matcher subexpression: 2) , replacement ] ifFalse: [ replacement ] ]
]

{ #category : 'private' }
PuntLogRedactor >> restoreSpacing: text [
 | restored |
 restored := text.
 #(9 10 11 12 13 133) do: [ :code |
   restored := restored copyReplaceAll: (self escapedCode: code) with: (Character value: code) asString ].
 ^ restored
]

{ #category : 'private' }
PuntLogRedactor >> token: text on: stream [ stream nextPutAll: (text utf8Encoded size > 2048 ifTrue: [ '[opaque]' ] ifFalse: [ text ])
]

{ #category : 'private' }
PuntLogRedactor >> tokenSeparator: character [ ^ #(9 10 12 13 32) includes: character codePoint
]

{ #category : 'private' }
PuntLogRedactor >> urlPattern [ ^ self expand: '[a-z][a-z0-9+.-]*\://[^\s<NEL><LS><PS>]*'
]

{ #category : 'private' }
PuntLogRedactor >> userInfoPattern [ ^ self expand: '[^\s"''<>/@:]+\:[^\s/@]+@[^\s]*'
]

{ #category : 'private' }
PuntLogRedactor >> validUnicode: aString [
 ^ aString allSatisfy: [ :character |
   character codePoint <= 16r10FFFF and: [ (character codePoint between: 16rD800 and: 16rDFFF) not ] ]
]
