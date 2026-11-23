"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Closed field kinds and enum members; identifiers are derived before queue admission. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryField new class name
  >>> #PuntTelemetryField
"
Class {
	#name : 'PuntTelemetryField',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'members',
		'required'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'instance creation' }
PuntTelemetryField class >> enum: aCollection required: aBoolean [ ^ self new kind: #enum members: aCollection required: aBoolean; yourself
]

{ #category : 'instance creation' }
PuntTelemetryField class >> kind: aKind required: aBoolean [ ^ self new kind: aKind members: #() required: aBoolean; yourself
]

{ #category : 'validation' }
PuntTelemetryField >> accepts: value [
 value ifNil: [ ^ required not ].
 kind = #enum ifTrue: [ ^ value isSymbol and: [ members includes: value ] ].
 kind = #boolean ifTrue: [ ^ #(True False) includes: value class name ].
 kind = #identifier ifTrue: [ ^ value isString and: [ value isSymbol not and: [ value size <= 65536 and: [ value utf8Encoded size <= 65536 ] ] ] ].
 ^ value isInteger and: [ (value between: -9223372036854775808 and: 9223372036854775807) and: [ kind = #integer or: [ value >= 0 ] ] ]
]

{ #category : 'converting' }
PuntTelemetryField >> encode: value saltAt: aHome [
 kind = #identifier ifTrue: [ ^ (PuntTelemetrySalt new hash: value home: aHome) ].
 ^ kind = #enum ifTrue: [ value asString ] ifFalse: [ value ]
]

{ #category : 'testing' }
PuntTelemetryField >> isValid [
 ^ (#(enum boolean integer duration count size length identifier) includes: kind) and: [
   (#(True False) includes: required class name) and: [ kind ~= #enum or: [
     members notEmpty and: [ members allSatisfy: [ :each | each isSymbol and: [ each matchesRegex: '[a-zA-Z][a-zA-Z0-9_\-]{0,63}' ] ] ] ] ] ]
]

{ #category : 'accessing' }
PuntTelemetryField >> kind [ ^ kind
]

{ #category : 'initialization' }
PuntTelemetryField >> kind: aKind members: aCollection required: aBoolean [ kind := aKind. members := aCollection asArray copy. required := aBoolean
]

{ #category : 'accessing' }
PuntTelemetryField >> members [ ^ members
]

{ #category : 'accessing' }
PuntTelemetryField >> required [ ^ required
]
