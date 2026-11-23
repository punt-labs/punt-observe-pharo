"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Installed smoke fixture with closed fields and explicit units. Object subclasses represent explicit service or value boundaries.

  PuntObserveSmokeEvent new class name
  >>> #PuntObserveSmokeEvent
"
Class {
	#name : 'PuntObserveSmokeEvent',
	#superclass : 'PuntTelemetrySchema',
	#category : 'PuntObserve-Smoke',
	#package : 'PuntObserve-Smoke'
}

{ #category : 'accessing' }
PuntObserveSmokeEvent class >> signalKind [ ^ #event
]

{ #category : 'accessing' }
PuntObserveSmokeEvent class >> signalName [ ^ PuntObserveSmoke tool , '.cli.checkpoint'
]
