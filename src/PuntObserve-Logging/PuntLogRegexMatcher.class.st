"
PHARO-LOG-5: Go-compatible ASCII word boundaries, including underscore, for credential patterns. Pharo default word boundaries use Unicode letters and omit underscore.

  PuntLogRegexMatcher new class name
  >>> #PuntLogRegexMatcher
"
Class {
	#name : 'PuntLogRegexMatcher',
	#superclass : 'RxMatcher',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'private' }
PuntLogRegexMatcher >> isWordChar: character [
 character ifNil: [ ^ false ].
 ^ (character between: $a and: $z) or: [ (character between: $A and: $Z) or: [
   (character between: $0 and: $9) or: [ character = $_ ] ] ]
]
