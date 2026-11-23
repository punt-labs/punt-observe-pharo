"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Guarded exporter isolates both thrown failures and false results behind worker-only fixed diagnostics. Object subclasses represent explicit service or value boundaries.

  PuntTelemetrySpanExporter new class name
  >>> #PuntTelemetrySpanExporter
"
Class {
	#name : 'PuntTelemetrySpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'delegate'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetrySpanExporter >> delegate [ ^ delegate
]

{ #category : 'accessing' }
PuntTelemetrySpanExporter >> delegate: anObject [ delegate := anObject
]

{ #category : 'exporting' }
PuntTelemetrySpanExporter >> export: batch [
 ^ [ (delegate export: batch) ifTrue: [ true ] ifFalse: [ PuntTelemetryDiagnostics noteFailure. false ] ]
   on: Error do: [ :error | PuntTelemetryDiagnostics noteFailure. false ]
]

{ #category : 'exporting' }
PuntTelemetrySpanExporter >> shutdown [
 ^ delegate shutdown
]
