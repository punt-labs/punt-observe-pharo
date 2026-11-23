"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: PHARO-LOG-5: numeric objects may carry arbitrary printable customer content. Object subclasses represent explicit service or value boundaries.

  PuntTestPrintableNumber new class name
  >>> #PuntTestPrintableNumber
"
Class {
	#name : 'PuntTestPrintableNumber',
	#superclass : 'Number',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'converting' }
PuntTestPrintableNumber >> asString [ ^ 'PRIVATE-NUMBER-CONTENT'
]
