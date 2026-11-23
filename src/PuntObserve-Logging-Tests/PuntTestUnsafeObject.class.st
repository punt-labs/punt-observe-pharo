"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior. Object is the service or value boundary.

  PuntTestUnsafeObject new class name
  >>> #PuntTestUnsafeObject
"
Class {
	#name : 'PuntTestUnsafeObject',
	#superclass : 'Object',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'printing' }
PuntTestUnsafeObject >> printOn: stream [ stream nextPutAll: 'PRIVATE-OBJECT-CONTENT'
]
