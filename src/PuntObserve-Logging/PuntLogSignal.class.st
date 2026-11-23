"
PHARO-LOG-1, PHARO-LOG-5, PHARO-LOG-6: Typed Beacon diagnostic with explicit metadata fields. Subclasses render approved ivars through fieldsOn: and field:value:on:, never arbitrary object printing.

  PuntLogSignal new class name
  >>> #PuntLogSignal
"
Class {
	#name : 'PuntLogSignal',
	#superclass : 'BeaconSignal',
	#instVars : [
		'component',
		'message'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogSignal class >> level [ ^ PuntLogLevel info
]

{ #category : 'accessing' }
PuntLogSignal >> component [ ^ component
]

{ #category : 'accessing' }
PuntLogSignal >> component: aString [ component := aString
]

{ #category : 'printing' }
PuntLogSignal >> field: name value: value on: stream [
 stream space; nextPutAll: name; nextPut: $=; nextPutAll: (PuntEscaper escape: (self safeString: value))
]

{ #category : 'printing' }
PuntLogSignal >> fieldsOn: stream [ ^ self
]

{ #category : 'initialization' }
PuntLogSignal >> initialize [ super initialize. component := 'application'. message := 'State changed'
]

{ #category : 'accessing' }
PuntLogSignal >> level [ ^ self class level
]

{ #category : 'accessing' }
PuntLogSignal >> message [ ^ message
]

{ #category : 'accessing' }
PuntLogSignal >> message: aString [ message := aString
]

{ #category : 'printing' }
PuntLogSignal >> printOneLineContentsOn: aStream [
 aStream nextPutAll: (PuntEscaper escape: message).
 self fieldsOn: aStream
]

{ #category : 'private' }
PuntLogSignal >> safeString: anObject [
 anObject isString ifTrue: [ ^ anObject ].
 (#(SmallInteger LargePositiveInteger LargeNegativeInteger SmallFloat64 BoxedFloat64 True False UndefinedObject) includes: anObject class name) ifTrue: [ ^ anObject asString ].
 ^ '[object]'
]
