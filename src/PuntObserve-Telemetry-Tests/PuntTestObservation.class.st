"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestObservation new class name
  >>> #PuntTestObservation
"
Class {
	#name : 'PuntTestObservation',
	#superclass : 'PuntTelemetrySchema',
	#instVars : [
		'outcome',
		'identifier',
		'items',
		'enabled'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestObservation class >> fieldSpecs [
 ^ { #outcome -> (PuntTelemetryField enum: #(ok failed) required: true).
     #identifier -> (PuntTelemetryField kind: #identifier required: false).
     #items -> (PuntTelemetryField kind: #count required: false).
     #enabled -> (PuntTelemetryField kind: #boolean required: false) } asDictionary
]

{ #category : 'accessing' }
PuntTestObservation class >> signalName [ ^ 'sample-tool.cli.operation'
]

{ #category : 'accessing' }
PuntTestObservation >> enabled [ ^ enabled
]

{ #category : 'accessing' }
PuntTestObservation >> enabled: anObject [ enabled := anObject
]

{ #category : 'accessing' }
PuntTestObservation >> identifier [ ^ identifier
]

{ #category : 'accessing' }
PuntTestObservation >> identifier: anObject [ identifier := anObject
]

{ #category : 'accessing' }
PuntTestObservation >> items [ ^ items
]

{ #category : 'accessing' }
PuntTestObservation >> items: anObject [ items := anObject
]

{ #category : 'accessing' }
PuntTestObservation >> outcome [ ^ outcome
]

{ #category : 'accessing' }
PuntTestObservation >> outcome: anObject [ outcome := anObject
]
