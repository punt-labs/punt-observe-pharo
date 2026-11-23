"
PHARO-LOG-5: single-line escaping shared by diagnostics and callers. Escapes control and format characters, preserving ordinary Unicode. Object is a stateless namespace.

  PuntEscaper escape: String lf
  >>> '\x0a'
"
Class {
	#name : 'PuntEscaper',
	#superclass : 'Object',
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}

{ #category : 'escaping' }
PuntEscaper class >> escape: aString [
 ^ String streamContents: [ :stream |
   aString do: [ :character |
     (self mustEscape: character)
       ifTrue: [ self writeEscape: character codePoint on: stream ]
       ifFalse: [ stream nextPut: character ] ] ]
]

{ #category : 'private' }
PuntEscaper class >> mustEscape: aCharacter [
 | code |
 code := aCharacter codePoint.
 ^ code < 32 or: [ (code between: 127 and: 159) or: [
   (#(16r2028 16r2029) includes: code) or: [ Unicode is: aCharacter inCategory: 2 ] ] ]
]

{ #category : 'private' }
PuntEscaper class >> writeEscape: anInteger on: aStream [
 | width |
 width := anInteger <= 255 ifTrue: [ 2 ] ifFalse: [ anInteger <= 65535 ifTrue: [ 4 ] ifFalse: [ 8 ] ].
 aStream nextPut: $\; nextPut: (width = 2 ifTrue: [ $x ] ifFalse: [ width = 4 ifTrue: [ $u ] ifFalse: [ $U ] ]).
 aStream nextPutAll: ((anInteger printStringBase: 16) asLowercase padLeftTo: width with: $0)
]
