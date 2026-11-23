"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Simulates a winning salt publisher appearing after a failed presence probe. Object subclasses represent explicit service or value boundaries.

  PuntTestLatePublishedSalt new class name
  >>> #PuntTestLatePublishedSalt
"
Class {
	#name : 'PuntTestLatePublishedSalt',
	#superclass : 'PuntTelemetrySalt',
	#instVars : [
		'attempts'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestLatePublishedSalt >> attempts [ ^ attempts
]

{ #category : 'initialization' }
PuntTestLatePublishedSalt >> initialize [ super initialize. attempts := 0
]

{ #category : 'private' }
PuntTestLatePublishedSalt >> readOnceAt: home [
 attempts := attempts + 1.
 attempts = 1 ifTrue: [ home ensureDirectories. self publishAt: home. PuntPermissionError signal: 'Simulated presence race' ].
 ^ super readOnceAt: home
]
