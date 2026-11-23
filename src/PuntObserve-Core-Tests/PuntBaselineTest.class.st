"
PHARO-LOG-1: Metacello recognizes the baseline without package-load startup effects.

  self new
  >>> a PuntBaselineTest
"
Class {
	#name : 'PuntBaselineTest',
	#superclass : 'TestCase',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'tests' }
PuntBaselineTest >> testBaselinePragma [ self assert: (BaselineOfPuntObserve >> #baseline:) pragmas first selector equals: #baseline
]
