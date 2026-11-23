"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Explicit consent and bounded retention; environment vetoes are read afresh at every start. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryConfig new class name
  >>> #PuntTelemetryConfig
"
Class {
	#name : 'PuntTelemetryConfig',
	#superclass : 'Object',
	#instVars : [
		'retentionDays',
		'disabled',
		'otlpConsent',
		'otlpEndpoint',
		'maintenanceSeconds'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetryConfig >> disabled [ ^ disabled
]

{ #category : 'accessing' }
PuntTelemetryConfig >> disabled: anObject [ disabled := anObject
]

{ #category : 'initialization' }
PuntTelemetryConfig >> initialize [ super initialize. retentionDays := 90. disabled := false. otlpConsent := false. maintenanceSeconds := 300
]

{ #category : 'testing' }
PuntTelemetryConfig >> isOffFor: tool [
 | environment key |
 disabled ifTrue: [ ^ true ].
 environment := OSEnvironment current.
 key := (tool asUppercase copyReplaceAll: '-' with: '_') , '_TELEMETRY'.
 ^ ((environment at: 'PUNT_TELEMETRY' ifAbsent: [ '' ]) asLowercase = 'off') or: [
   (environment at: key ifAbsent: [ '' ]) asLowercase = 'off' ]
]

{ #category : 'accessing' }
PuntTelemetryConfig >> maintenanceSeconds [ ^ maintenanceSeconds
]

{ #category : 'accessing' }
PuntTelemetryConfig >> maintenanceSeconds: anObject [ maintenanceSeconds := anObject
]

{ #category : 'accessing' }
PuntTelemetryConfig >> otlpConsent [ ^ otlpConsent
]

{ #category : 'accessing' }
PuntTelemetryConfig >> otlpConsent: anObject [ otlpConsent := anObject
]

{ #category : 'accessing' }
PuntTelemetryConfig >> otlpEndpoint [ ^ otlpEndpoint
]

{ #category : 'accessing' }
PuntTelemetryConfig >> otlpEndpoint: anObject [ otlpEndpoint := anObject
]

{ #category : 'accessing' }
PuntTelemetryConfig >> retentionDays [ ^ retentionDays
]

{ #category : 'accessing' }
PuntTelemetryConfig >> retentionDays: anObject [ retentionDays := anObject
]

{ #category : 'testing' }
PuntTelemetryConfig >> usesOtlp [ ^ otlpConsent and: [ otlpEndpoint notNil ]
]

{ #category : 'private' }
PuntTelemetryConfig >> validateEndpoint [
 | url |
 otlpEndpoint isString ifFalse: [ self error: 'Invalid endpoint' ].
 url := ZnUrl fromString: otlpEndpoint.
 ((url scheme = #https or: [ url scheme = #http and: [ #('127.0.0.1' '::1') includes: url host ] ]) and: [
   url host notEmpty and: [ url username isNil and: [ url password isNil and: [ url query isNil and: [ url fragment isNil ] ] ] ] ])
   ifFalse: [ self error: 'Invalid endpoint' ]
]

{ #category : 'validation' }
PuntTelemetryConfig >> validatedCopy [
 (retentionDays isInteger and: [ retentionDays between: 1 and: 3650 ]) ifFalse: [ self error: 'Invalid retention' ].
 (maintenanceSeconds isInteger and: [ maintenanceSeconds between: 1 and: 3600 ]) ifFalse: [ self error: 'Invalid maintenance interval' ].
 (#(True False) includes: disabled class name) ifFalse: [ self error: 'Invalid disabled flag' ].
 (#(True False) includes: otlpConsent class name) ifFalse: [ self error: 'Invalid consent flag' ].
 otlpEndpoint ifNotNil: [ self validateEndpoint ].
 ^ self copy
]
