"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestCounter new class name
  >>> #PuntTestCounter
"
Class {
	#name : 'PuntTestCounter',
	#superclass : 'PuntTestObservation',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestCounter class >> signalKind [ ^ #counter
]

{ #category : 'accessing' }
PuntTestCounter class >> signalName [ ^ 'sample-tool.cli.counter'
]

{ #category : 'accessing' }
PuntTestCounter class >> unit [ ^ '1'
]
