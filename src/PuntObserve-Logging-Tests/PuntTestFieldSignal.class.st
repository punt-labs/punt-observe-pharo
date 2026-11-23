"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntTestFieldSignal new class name
  >>> #PuntTestFieldSignal
"
Class {
	#name : 'PuntTestFieldSignal',
	#superclass : 'PuntLogSignal',
	#instVars : [
		'detail'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntTestFieldSignal >> detail: value [ detail := value
]

{ #category : 'printing' }
PuntTestFieldSignal >> fieldsOn: stream [ self field: 'detail' value: detail on: stream
]
