"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryImagesTest new class name
  >>> #PuntTelemetryImagesTest
"
Class {
	#name : 'PuntTelemetryImagesTest',
	#superclass : 'PuntHomeTest',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTelemetryImagesTest >> defaultTimeLimit [ ^ 240 seconds
]

{ #category : 'private' }
PuntTelemetryImagesTest >> shellQuote: text [ ^ '''' , (text copyReplaceAll: '''' with: '''"''"''') , ''''
]

{ #category : 'tests' }
PuntTelemetryImagesTest >> testIndependentImagesAndBusyTimeout [
 | command result |
 command := String streamContents: [ :stream |
   stream nextPutAll: 'python3 scripts/telemetry-images.py '.
   { Smalltalk vm fullPath. Smalltalk imagePath. sandbox pathString } do: [ :arg | stream nextPutAll: (self shellQuote: arg); space ] ].
 result := LibC resultOfCommand: command , ' 2>&1'.
 self assert: (result includesSubstring: 'PUNT-TELEMETRY-IMAGES-OK') description: result
]
