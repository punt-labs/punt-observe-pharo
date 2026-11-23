"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Abstract typed operation version. Subclasses declare closed fields matching their slots; never accept attribute bags. Object subclasses represent explicit service or value boundaries.

  PuntTelemetrySchema new class name
  >>> #PuntTelemetrySchema
"
Class {
	#name : 'PuntTelemetrySchema',
	#superclass : 'Object',
	#instVars : [
		'startedAt',
		'duration',
		'amount'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetrySchema class >> fieldSpecs [ ^ Dictionary new
]

{ #category : 'accessing' }
PuntTelemetrySchema class >> schemaVersion [ ^ 1
]

{ #category : 'accessing' }
PuntTelemetrySchema class >> signalKind [ ^ #span
]

{ #category : 'accessing' }
PuntTelemetrySchema class >> signalName [ ^ self subclassResponsibility
]

{ #category : 'accessing' }
PuntTelemetrySchema class >> unit [ ^ nil
]

{ #category : 'validation' }
PuntTelemetrySchema class >> validateDefinition [
 self validateIdentity. self validateFields
]

{ #category : 'validation' }
PuntTelemetrySchema class >> validateFields [
 | fields |
 fields := self fieldSpecs.
 (fields size <= 24 and: [ (fields keys collect: [ :fieldName | fieldName asString ]) asSet size = fields size and: [ (fields keys collect: [ :fieldName | fieldName asString ]) asSet = (self allInstVarNames reject: [ :fieldName | #(startedAt duration amount) includes: fieldName asSymbol ]) asSet ] ])
   ifFalse: [ self error: 'Unknown field' ].
 fields keysAndValuesDo: [ :fieldName :field |
   ((fieldName asString matchesRegex: '[a-z][a-z0-9_.\-]{0,63}') and: [ field isValid ]) ifFalse: [ self error: 'Invalid field declaration' ] ]
]

{ #category : 'validation' }
PuntTelemetrySchema class >> validateIdentity [
 ((self signalName matchesRegex: '[a-z][a-z0-9\-]*\.[a-z][a-z0-9_\-]*\.[a-z][a-z0-9_\-]*') and: [ self signalName size <= 127 ]) ifFalse: [ self error: 'Invalid signal name' ].
 (self schemaVersion isInteger and: [ self schemaVersion between: 1 and: 2147483647 ]) ifFalse: [ self error: 'Invalid version' ].
 (#(span event counter histogram) includes: self signalKind) ifFalse: [ self error: 'Invalid kind' ].
 (#(counter histogram) includes: self signalKind)
   ifTrue: [ (#('1' 'By' 'ms') includes: self unit) ifFalse: [ self error: 'Invalid unit' ] ]
   ifFalse: [ self unit ifNotNil: [ self error: 'Unexpected unit' ] ]
]

{ #category : 'accessing' }
PuntTelemetrySchema >> amount [ ^ amount
]

{ #category : 'accessing' }
PuntTelemetrySchema >> amount: anObject [ amount := anObject
]

{ #category : 'validation' }
PuntTelemetrySchema >> asRecordAt: home [
 | attributes specs |
 self class validateDefinition.
 (startedAt class includesBehavior: DateAndTime) ifFalse: [ self error: 'Invalid timestamp' ].
 { duration. amount } do: [ :each | (each isInteger and: [ each between: 0 and: 9223372036854775807 ]) ifFalse: [ self error: 'Invalid measurement' ] ].
 specs := self class fieldSpecs. attributes := Dictionary new.
 specs keysAndValuesDo: [ :name :field |
   | value |
   value := (self class slotNamed: name asSymbol) read: self.
   (field accepts: value) ifFalse: [ self error: 'Invalid field' ].
   value ifNotNil: [ attributes at: name asString put: (field encode: value saltAt: home) ] ].
 ^ PuntTelemetryRecord new schema: self attributes: attributes; yourself
]

{ #category : 'accessing' }
PuntTelemetrySchema >> duration [ ^ duration
]

{ #category : 'accessing' }
PuntTelemetrySchema >> duration: anObject [ duration := anObject
]

{ #category : 'initialization' }
PuntTelemetrySchema >> initialize [ super initialize. startedAt := DateAndTime now. duration := 0. amount := 1
]

{ #category : 'accessing' }
PuntTelemetrySchema >> startedAt [ ^ startedAt
]

{ #category : 'accessing' }
PuntTelemetrySchema >> startedAt: anObject [ startedAt := anObject
]
