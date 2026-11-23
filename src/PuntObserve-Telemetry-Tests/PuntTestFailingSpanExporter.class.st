"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestFailingSpanExporter new class name
  >>> #PuntTestFailingSpanExporter
"
Class {
	#name : 'PuntTestFailingSpanExporter',
	#superclass : 'OTSpanExporter',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'exporting' }
PuntTestFailingSpanExporter >> export: batch [ self error: 'PRIVATE-EXPORT-ERROR'
]
