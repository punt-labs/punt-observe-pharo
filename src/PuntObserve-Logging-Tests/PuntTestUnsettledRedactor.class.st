"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntTestUnsettledRedactor new class name
  >>> #PuntTestUnsettledRedactor
"
Class {
	#name : 'PuntTestUnsettledRedactor',
	#superclass : 'PuntLogRedactor',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'private' }
PuntTestUnsettledRedactor >> mask: text [ ^ text , 'x'
]
