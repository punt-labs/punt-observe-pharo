"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Worker-only rate-limited metadata-only diagnostics; no rejected values or exception objects. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryDiagnostics new class name
  >>> #PuntTelemetryDiagnostics
"
Class {
	#name : 'PuntTelemetryDiagnostics',
	#superclass : 'Object',
	#classVars : [
		'LastNotice'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'logging' }
PuntTelemetryDiagnostics class >> noteFailure [
 | now |
 now := Time millisecondClockValue.
 (LastNotice notNil and: [ (Time millisecondsSince: LastNotice) < 60000 ]) ifTrue: [ ^ self ].
 LastNotice := now.
 [ (PuntLogSignal new component: 'telemetry'; message: 'Telemetry operation dropped or failed') emit ] on: Error do: [ :error | ^ self ]
]

{ #category : 'initialization' }
PuntTelemetryDiagnostics class >> resetSession [ LastNotice := nil
]
