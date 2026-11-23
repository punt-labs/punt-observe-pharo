"
PHARO-LOG-5: ordinary Unicode, empty inputs and all control/format character families remain single-line.

  self new
  >>> a PuntEscaperTest
"
Class {
	#name : 'PuntEscaperTest',
	#superclass : 'TestCase',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'tests' }
PuntEscaperTest >> testC0AndC1 [
 0 to: 159 do: [ :code |
   (code < 32 or: [ code >= 127 ]) ifTrue: [
     self assert: (PuntEscaper escape: (Character value: code) asString)
       equals: (String streamContents: [ :stream | stream nextPutAll: '\x'; nextPutAll: ((code printStringBase: 16) asLowercase padLeftTo: 2 with: $0) ]) ] ]
]

{ #category : 'tests' }
PuntEscaperTest >> testEmpty [ self assert: (PuntEscaper escape: '') equals: ''
]

{ #category : 'tests' }
PuntEscaperTest >> testForgedLine [
 self assert: (PuntEscaper escape: 'a' , String crlf , (Character value: 27) asString , '[31m') equals: 'a\x0d\x0a\x1b[31m'
]

{ #category : 'tests' }
PuntEscaperTest >> testLiteralBackslashesAreUnambiguous [
 self assert: (PuntEscaper escape: '\x0a\\') equals: '\x5cx0a\x5c\x5c'

]

{ #category : 'tests' }
PuntEscaperTest >> testOrdinaryUnicode [ self assert: (PuntEscaper escape: 'café 日本語') equals: 'café 日本語'
]

{ #category : 'tests' }
PuntEscaperTest >> testSeparatorsAndBidi [
 #(16r2028 16r2029 16r202a 16r202e 16r2066 16r2069 16r200e 16r200f 16rfeff) do: [ :code |
   self assert: (PuntEscaper escape: (Character value: code) asString)
     equals: (String streamContents: [ :stream | stream nextPutAll: '\u'; nextPutAll: ((code printStringBase: 16) asLowercase padLeftTo: 4 with: $0) ]) ]
]

{ #category : 'tests' }
PuntEscaperTest >> testSupplementaryFormat [
 self assert: (PuntEscaper escape: (Character value: 16re0001) asString) equals: '\U000e0001'
]
