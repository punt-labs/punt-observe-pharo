"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: An isolated smoke report path without environment mutation. Object subclasses represent explicit service or value boundaries.

  PuntTestSmoke new class name
  >>> #PuntTestSmoke
"
Class {
	#name : 'PuntTestSmoke',
	#superclass : 'PuntObserveSmoke',
	#instVars : [
		'report'
	],
	#category : 'PuntObserve-Smoke-Tests',
	#package : 'PuntObserve-Smoke-Tests'
}

{ #category : 'private' }
PuntTestSmoke >> reportFile [ ^ report
]

{ #category : 'accessing' }
PuntTestSmoke >> reportFile: file [ report := file
]
