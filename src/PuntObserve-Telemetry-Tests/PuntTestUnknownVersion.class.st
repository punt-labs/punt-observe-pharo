"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestUnknownVersion new class name
  >>> #PuntTestUnknownVersion
"
Class {
	#name : 'PuntTestUnknownVersion',
	#superclass : 'PuntTestObservation',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestUnknownVersion class >> schemaVersion [ ^ 2
]
