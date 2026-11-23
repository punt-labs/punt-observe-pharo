"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Guarded exporter isolates both thrown failures and false results behind worker-only fixed diagnostics. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryMetricExporter new class name
  >>> #PuntTelemetryMetricExporter
"
Class {
	#name : 'PuntTelemetryMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'delegate'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetryMetricExporter >> delegate [ ^ delegate
]

{ #category : 'accessing' }
PuntTelemetryMetricExporter >> delegate: anObject [ delegate := anObject
]

{ #category : 'exporting' }
PuntTelemetryMetricExporter >> export: batch [
 ^ [ (delegate export: batch) ifTrue: [ true ] ifFalse: [ PuntTelemetryDiagnostics noteFailure. false ] ]
   on: Error do: [ :error | PuntTelemetryDiagnostics noteFailure. false ]
]

{ #category : 'lifecycle' }
PuntTelemetryMetricExporter >> shutdown [ delegate shutdown
]
