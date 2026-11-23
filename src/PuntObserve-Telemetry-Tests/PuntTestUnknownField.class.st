"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestUnknownField new class name
  >>> #PuntTestUnknownField
"
Class {
	#name : 'PuntTestUnknownField',
	#superclass : 'PuntTestObservation',
	#instVars : [
		'content'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestUnknownField >> content [ ^ content
]

{ #category : 'accessing' }
PuntTestUnknownField >> content: anObject [ content := anObject
]
