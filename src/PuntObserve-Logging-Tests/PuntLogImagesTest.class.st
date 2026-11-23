"
PHARO-LOG-4, PHARO-LOG-6: Acceptance fixture for PHARO-LOG-4, PHARO-LOG-6; deterministic isolation of logging behavior.

  PuntLogImagesTest new class name
  >>> #PuntLogImagesTest
"
Class {
	#name : 'PuntLogImagesTest',
	#superclass : 'PuntHomeTest',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntLogImagesTest >> defaultTimeLimit [ ^ 240 seconds
]

{ #category : 'private' }
PuntLogImagesTest >> shellQuote: text [ ^ '''' , (text copyReplaceAll: '''' with: '''"''"''') , ''''
]

{ #category : 'tests' }
PuntLogImagesTest >> testConcurrentImagesAcrossRetentionWindow [
 | command result |
 command := String streamContents: [ :stream |
   stream nextPutAll: 'python3 scripts/logging-images.py '.
   { Smalltalk vm fullPath. Smalltalk imagePath. sandbox pathString } do: [ :arg |
     stream nextPutAll: (self shellQuote: arg); space ] ].
 result := LibC resultOfCommand: command , ' 2>&1'.
 self assert: (result includesSubstring: 'PUNT-IMAGES-OK') description: result
]
