"
PHARO-LOG-5: Error diagnostic retaining only an exception class name, never exception text or context.

  PuntLogErrorSignal new class name
  >>> #PuntLogErrorSignal
"
Class {
	#name : 'PuntLogErrorSignal',
	#superclass : 'PuntLogSignal',
	#instVars : [
		'errorClass'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogErrorSignal class >> level [ ^ PuntLogLevel error
]

{ #category : 'error handling' }
PuntLogErrorSignal >> error: anError [ errorClass := anError class name
]

{ #category : 'printing' }
PuntLogErrorSignal >> fieldsOn: stream [ self field: 'errorClass' value: errorClass on: stream
]
