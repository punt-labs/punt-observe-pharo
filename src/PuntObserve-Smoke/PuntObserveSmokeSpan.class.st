"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Installed smoke fixture with closed fields and explicit units. Object subclasses represent explicit service or value boundaries.

  PuntObserveSmokeSpan new class name
  >>> #PuntObserveSmokeSpan
"
Class {
	#name : 'PuntObserveSmokeSpan',
	#superclass : 'PuntTelemetrySchema',
	#instVars : [
		'outcome',
		'subject'
	],
	#category : 'PuntObserve-Smoke',
	#package : 'PuntObserve-Smoke'
}

{ #category : 'accessing' }
PuntObserveSmokeSpan class >> fieldSpecs [
 ^ { #outcome -> (PuntTelemetryField enum: #(ok failed) required: true).
     #subject -> (PuntTelemetryField kind: #identifier required: true) } asDictionary
]

{ #category : 'accessing' }
PuntObserveSmokeSpan class >> signalName [ ^ PuntObserveSmoke tool , '.cli.operation'
]

{ #category : 'accessing' }
PuntObserveSmokeSpan >> outcome [ ^ outcome
]

{ #category : 'accessing' }
PuntObserveSmokeSpan >> outcome: aSymbol [ outcome := aSymbol
]

{ #category : 'accessing' }
PuntObserveSmokeSpan >> subject [ ^ subject
]

{ #category : 'accessing' }
PuntObserveSmokeSpan >> subject: aString [ subject := aString
]
