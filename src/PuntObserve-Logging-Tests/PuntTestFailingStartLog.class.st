"
PHARO-LOG-2: Fails after subscribing so failed-start cleanup can be tested.

  PuntTestFailingStartLog new class name
  >>> #PuntTestFailingStartLog
"
Class {
	#name : 'PuntTestFailingStartLog',
	#superclass : 'PuntLog',
	#classVars : [
		'LastAttempt'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntTestFailingStartLog class >> lastAttempt [ ^ LastAttempt
]

{ #category : 'accessing' }
PuntTestFailingStartLog class >> lastAttempt: logger [ LastAttempt := logger
]

{ #category : 'registration' }
PuntTestFailingStartLog >> start [ self class lastAttempt: self. super start. self error: 'Synthetic start failure'
]
