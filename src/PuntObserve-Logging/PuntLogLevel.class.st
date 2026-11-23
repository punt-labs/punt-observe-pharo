"
PHARO-LOG-6: Ordered diagnostic severity values and their uppercase labels. Object is the service or value boundary.

  PuntLogLevel new class name
  >>> #PuntLogLevel
"
Class {
	#name : 'PuntLogLevel',
	#superclass : 'Object',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogLevel class >> debug [ ^ 10
]

{ #category : 'error handling' }
PuntLogLevel class >> error [ ^ 40
]

{ #category : 'accessing' }
PuntLogLevel class >> info [ ^ 20
]

{ #category : 'accessing' }
PuntLogLevel class >> label: aLevel [ ^ (#('DEBUG' 'INFO' 'WARNING' 'ERROR') at: (#(10 20 30 40) indexOf: aLevel))
]

{ #category : 'validation' }
PuntLogLevel class >> validate: aLevel [ (#(10 20 30 40) includes: aLevel) ifFalse: [ self error: 'Invalid diagnostic level' ]
]

{ #category : 'accessing' }
PuntLogLevel class >> warning [ ^ 30
]
