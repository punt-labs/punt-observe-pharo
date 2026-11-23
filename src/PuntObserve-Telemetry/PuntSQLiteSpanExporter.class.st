"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: SQLite span and event snapshot adapter; error containment stays on the worker. Object subclasses represent explicit service or value boundaries.

  PuntSQLiteSpanExporter new class name
  >>> #PuntSQLiteSpanExporter
"
Class {
	#name : 'PuntSQLiteSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'store'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'exporting' }
PuntSQLiteSpanExporter >> export: spans [
 ^ [ store transaction: [ spans do: [ :span | store insert: (store spanValues: span) ] ]. true ] on: Error do: [ :error | PuntTelemetryDiagnostics noteFailure. false ]
]

{ #category : 'accessing' }
PuntSQLiteSpanExporter >> store: aStore [ store := aStore
]
