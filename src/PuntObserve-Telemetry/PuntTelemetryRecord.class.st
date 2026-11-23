"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Internal validated snapshot containing only closed metadata and already-hashed identifiers. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryRecord new class name
  >>> #PuntTelemetryRecord
"
Class {
	#name : 'PuntTelemetryRecord',
	#superclass : 'Object',
	#instVars : [
		'name',
		'version',
		'kind',
		'unit',
		'startedAt',
		'endedAt',
		'amount',
		'attributes'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetryRecord >> amount [ ^ amount
]

{ #category : 'accessing' }
PuntTelemetryRecord >> attributes [ ^ attributes
]

{ #category : 'accessing' }
PuntTelemetryRecord >> endedAt [ ^ endedAt
]

{ #category : 'accessing' }
PuntTelemetryRecord >> kind [ ^ kind
]

{ #category : 'accessing' }
PuntTelemetryRecord >> name [ ^ name
]

{ #category : 'initialization' }
PuntTelemetryRecord >> schema: schema attributes: values [
 name := schema class signalName copy. version := schema class schemaVersion.
 kind := schema class signalKind. unit := schema class unit.
 startedAt := schema startedAt. endedAt := startedAt + schema duration milliSeconds.
 amount := schema amount. attributes := values.
 attributes at: 'punt.schema.version' put: version
]

{ #category : 'accessing' }
PuntTelemetryRecord >> startedAt [ ^ startedAt
]

{ #category : 'accessing' }
PuntTelemetryRecord >> unit [ ^ unit
]

{ #category : 'accessing' }
PuntTelemetryRecord >> version [ ^ version
]
