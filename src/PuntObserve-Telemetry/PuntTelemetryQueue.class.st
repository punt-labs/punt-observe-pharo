"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: A hard capacity of 1024; operation-side admission never waits on a mutex or exporter. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryQueue new class name
  >>> #PuntTelemetryQueue
"
Class {
	#name : 'PuntTelemetryQueue',
	#superclass : 'Object',
	#instVars : [
		'items',
		'mutex',
		'accepting',
		'dropped',
		'wake'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'testing' }
PuntTelemetryQueue >> canAccept [ ^ accepting and: [ items size < 1024 ]
]

{ #category : 'operating' }
PuntTelemetryQueue >> close [ mutex critical: [ accepting := false ]. wake signal
]

{ #category : 'operating' }
PuntTelemetryQueue >> discard [ mutex critical: [ items removeAll ]
]

{ #category : 'operating' }
PuntTelemetryQueue >> drop [ dropped := dropped + 1. ^ false
]

{ #category : 'accessing' }
PuntTelemetryQueue >> dropped [ ^ dropped
]

{ #category : 'initialization' }
PuntTelemetryQueue >> initialize [ super initialize. items := OrderedCollection new: 1024. mutex := Mutex new. accepting := true. dropped := 0. wake := Semaphore new
]

{ #category : 'testing' }
PuntTelemetryQueue >> isEmpty [ ^ items isEmpty
]

{ #category : 'operating' }
PuntTelemetryQueue >> pop [ ^ mutex critical: [ items ifEmpty: [ nil ] ifNotEmpty: [ items removeFirst ] ]
]

{ #category : 'operating' }
PuntTelemetryQueue >> push: record [
 | result |
 result := mutex tryEnterCritical: [ (accepting and: [ items size < 1024 ]) ifTrue: [ items addLast: record. wake signal. true ] ifFalse: [ false ] ] ifLocked: [ false ].
 ^ result ifTrue: [ true ] ifFalse: [ self drop ]
]

{ #category : 'accessing' }
PuntTelemetryQueue >> size [ ^ items size
]

{ #category : 'operating' }
PuntTelemetryQueue >> wait [ wake waitTimeoutMilliseconds: 50
]
