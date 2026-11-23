"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Installed smoke fixture with closed fields and explicit units. Object subclasses represent explicit service or value boundaries.

  PuntObserveSmokeCounter new class name
  >>> #PuntObserveSmokeCounter
"
Class {
	#name : 'PuntObserveSmokeCounter',
	#superclass : 'PuntTelemetrySchema',
	#category : 'PuntObserve-Smoke',
	#package : 'PuntObserve-Smoke'
}

{ #category : 'accessing' }
PuntObserveSmokeCounter class >> signalKind [ ^ #counter
]

{ #category : 'accessing' }
PuntObserveSmokeCounter class >> signalName [ ^ PuntObserveSmoke tool , '.cli.operations'
]

{ #category : 'accessing' }
PuntObserveSmokeCounter class >> unit [ ^ '1'
]
