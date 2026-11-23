"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestHistogram new class name
  >>> #PuntTestHistogram
"
Class {
	#name : 'PuntTestHistogram',
	#superclass : 'PuntTestObservation',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestHistogram class >> signalKind [ ^ #histogram
]

{ #category : 'accessing' }
PuntTestHistogram class >> signalName [ ^ 'sample-tool.cli.histogram'
]

{ #category : 'accessing' }
PuntTestHistogram class >> unit [ ^ 'ms'
]
