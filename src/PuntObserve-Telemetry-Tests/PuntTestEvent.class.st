"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestEvent new class name
  >>> #PuntTestEvent
"
Class {
	#name : 'PuntTestEvent',
	#superclass : 'PuntTestObservation',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestEvent class >> signalKind [ ^ #event
]

{ #category : 'accessing' }
PuntTestEvent class >> signalName [ ^ 'sample-tool.cli.event'
]
