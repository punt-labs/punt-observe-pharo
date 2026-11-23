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

{ #category : 'private' }
PuntTelemetryImagesTest class >> publish: aBlock to: file [
 | temporary |
 temporary := file parent / (file basename , '.pending').
 [ temporary writeStreamDo: aBlock.
   temporary renameTo: file basename ] ifCurtailed: [ temporary ensureDelete ]
]

{ #category : 'accessing' }
PuntTelemetryImagesTest >> defaultTimeLimit [ ^ 240 seconds
]

{ #category : 'private' }
PuntTelemetryImagesTest >> shellQuote: text [ ^ '''' , (text copyReplaceAll: '''' with: '''"''"''') , ''''
]

{ #category : 'tests' }
PuntTelemetryImagesTest >> testElapsedMarkerIsInvisibleUntilComplete [
 | target entered release done writer |
 target := sandbox / 'elapsed'. entered := Semaphore new. release := Semaphore new. done := Semaphore new.
 writer := [
   [ self class publish: [ :stream |
       stream nextPutAll: '2'. entered signal. release wait. stream nextPutAll: '00' ] to: target
   ] ensure: [ done signal ] ] fork.
 [ self deny: (entered waitTimeoutMilliseconds: 1000).
   self deny: target exists.
   release signal.
   self deny: (done waitTimeoutMilliseconds: 1000).
   self assert: target contents equals: '200'
 ] ensure: [ release signal. writer terminate ].
 target ensureDelete.
 self should: [ self class publish: [ :stream | stream nextPutAll: 'bad'. self error: 'Incomplete marker' ] to: target ] raise: Error.
 self deny: target exists.
 self deny: (sandbox / 'elapsed.pending') exists
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
