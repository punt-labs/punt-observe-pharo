"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: SQLite delta metric snapshot adapter preserving schema identity, units and aggregation. Object subclasses represent explicit service or value boundaries.

  PuntSQLiteMetricExporter new class name
  >>> #PuntSQLiteMetricExporter
"
Class {
	#name : 'PuntSQLiteMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'store'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'exporting' }
PuntSQLiteMetricExporter >> export: snapshot [
 ^ [ store transaction: [ snapshot metrics do: [ :metric | metric points do: [ :point | store insert: (store metricValues: metric point: point) ] ] ]. true ]
   on: Error do: [ :error | PuntTelemetryDiagnostics noteFailure. false ]
]

{ #category : 'accessing' }
PuntSQLiteMetricExporter >> store: aStore [ store := aStore
]
