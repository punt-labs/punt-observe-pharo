"
PHARO-LOG-6: Correlated background outcome with an optional error class, not an exception object.

  PuntLogWorkSignal new class name
  >>> #PuntLogWorkSignal
"
Class {
	#name : 'PuntLogWorkSignal',
	#superclass : 'PuntLogSignal',
	#instVars : [
		'correlation',
		'outcome',
		'errorClass'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogWorkSignal >> correlation: aString [ correlation := aString
]

{ #category : 'error handling' }
PuntLogWorkSignal >> error: anError [ errorClass := anError class name
]

{ #category : 'printing' }
PuntLogWorkSignal >> fieldsOn: stream [ self field: 'correlation' value: correlation on: stream. self field: 'outcome' value: outcome on: stream. self field: 'errorClass' value: errorClass on: stream
]

{ #category : 'accessing' }
PuntLogWorkSignal >> outcome: aSymbol [ outcome := aSymbol
]
