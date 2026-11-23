"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestForbiddenTelemetry new class name
  >>> #PuntTestForbiddenTelemetry
"
Class {
	#name : 'PuntTestForbiddenTelemetry',
	#superclass : 'Object',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'testing' }
PuntTestForbiddenTelemetry >> provider [ ^ [ OTTracerProvider ]
]
