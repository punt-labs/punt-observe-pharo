"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestStalledSpanExporter new class name
  >>> #PuntTestStalledSpanExporter
"
Class {
	#name : 'PuntTestStalledSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'entered',
		'release'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestStalledSpanExporter >> entered [ ^ entered
]

{ #category : 'exporting' }
PuntTestStalledSpanExporter >> export: batch [ entered signal. release wait. ^ true
]

{ #category : 'initialization' }
PuntTestStalledSpanExporter >> initialize [ super initialize. entered := Semaphore new. release := Semaphore new
]

{ #category : 'dependencies' }
PuntTestStalledSpanExporter >> release [ release signal
]
