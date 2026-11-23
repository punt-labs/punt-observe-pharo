"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntTestFailingRedactor new class name
  >>> #PuntTestFailingRedactor
"
Class {
	#name : 'PuntTestFailingRedactor',
	#superclass : 'PuntLogRedactor',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'private' }
PuntTestFailingRedactor >> mask: text [ self error: 'Redactor unavailable'
]
