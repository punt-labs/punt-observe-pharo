"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Typed pre-enqueue validation and HMAC snapshots; independent vetoes create a no-op before any store or worker. Object subclasses represent explicit service or value boundaries.

  PuntTelemetry new class name
  >>> #PuntTelemetry
"
Class {
	#name : 'PuntTelemetry',
	#superclass : 'Object',
	#instVars : [
		'schemas',
		'home',
		'queue',
		'worker'
	],
	#classVars : [
		'Configuration',
		'Current',
		'Guard',
		'SchemaClasses',
		'Tool'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetry class >> current [ ^ Current
]

{ #category : 'private' }
PuntTelemetry class >> guard [ ^ Guard ifNil: [ Guard := Mutex new ]
]

{ #category : 'recording' }
PuntTelemetry class >> record: observation [
 | current |
 current := Current.
 ^ current ifNil: [ false ] ifNotNil: [ current record: observation ]
]

{ #category : 'system startup' }
PuntTelemetry class >> shutDown: quitting [ Current ifNotNil: [ Current shutdown ]. Current := nil. Guard := nil
]

{ #category : 'operating' }
PuntTelemetry class >> shutdown [ self guard critical: [ Current ifNotNil: [ Current shutdown ]. Current := nil. Tool := nil. Configuration := nil. SchemaClasses := nil ]
]

{ #category : 'operating' }
PuntTelemetry class >> startTool: tool config: config schemas: classes [
 PuntHome validateTool: tool.
 ^ self guard critical: [ Current ifNil: [
   Current := self new tool: tool config: config schemas: classes.
   Tool := tool copy. Configuration := config validatedCopy. SchemaClasses := classes asArray copy.
   (SessionManager default hasRegistered: self name) ifFalse: [ SessionManager default registerUserClassNamed: self name ] ]. Current ]
]

{ #category : 'system startup' }
PuntTelemetry class >> startUp: resuming [
 PuntTelemetryDiagnostics resetSession.
 Current ifNotNil: [ Current shutdown ]. Current := nil. Guard := nil.
 Tool ifNotNil: [ self startTool: Tool config: Configuration schemas: SchemaClasses ]
]

{ #category : 'accessing' }
PuntTelemetry >> dropped [ ^ queue ifNil: [ 0 ] ifNotNil: [ queue dropped ]
]

{ #category : 'accessing' }
PuntTelemetry >> home [ ^ home
]

{ #category : 'testing' }
PuntTelemetry >> isEnabled [ ^ worker notNil
]

{ #category : 'accessing' }
PuntTelemetry >> queue [ ^ queue
]

{ #category : 'recording' }
PuntTelemetry >> record: observation [
 ^ [ queue ifNil: [ false ] ifNotNil: [
   (queue canAccept and: [ schemas includes: observation class ]) ifTrue: [ queue push: (observation asRecordAt: home) ] ifFalse: [ queue drop ] ] ]
   on: Error do: [ :error | queue ifNil: [ false ] ifNotNil: [ queue drop ] ]
]

{ #category : 'operating' }
PuntTelemetry >> shutdown [ worker ifNotNil: [ worker shutdown. worker := nil ]. queue ifNotNil: [ queue close ]
]

{ #category : 'initialization' }
PuntTelemetry >> tool: tool config: aConfig schemas: classes [
 | config |
 config := aConfig validatedCopy.
 (config isOffFor: tool) ifTrue: [ ^ self ].
 schemas := classes asArray copy. self validateSchemasFor: tool.
 home := PuntHome forTool: tool. queue := PuntTelemetryQueue new.
 worker := PuntTelemetryWorker new queue: queue home: home config: config.
 worker start.
 ^ self
]

{ #category : 'private' }
PuntTelemetry >> validateSchemasFor: tool [
 | identities prefix |
 prefix := tool , '.'.
 identities := schemas collect: [ :class |
   | key |
   (class inheritsFrom: PuntTelemetrySchema) ifFalse: [ self error: 'Invalid schema class' ].
   class validateDefinition.
   (class signalName beginsWith: prefix) ifFalse: [ self error: 'Invalid schema owner' ].
   key := { class signalName. class schemaVersion }.
   key ].
 identities asSet size = identities size ifFalse: [ self error: 'Duplicate schema' ]
]

{ #category : 'accessing' }
PuntTelemetry >> worker [ ^ worker
]
