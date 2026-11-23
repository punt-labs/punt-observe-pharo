"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTestRacingSalt new class name
  >>> #PuntTestRacingSalt
"
Class {
	#name : 'PuntTestRacingSalt',
	#superclass : 'PuntTelemetrySalt',
	#classVars : [
		'Go',
		'Ready'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestRacingSalt class >> go [ ^ Go
]

{ #category : 'initialization' }
PuntTestRacingSalt class >> prepare [ Ready := Semaphore new. Go := Semaphore new
]

{ #category : 'accessing' }
PuntTestRacingSalt class >> ready [ ^ Ready
]

{ #category : 'private' }
PuntTestRacingSalt >> entropy [ self class ready signal. self class go wait. ^ super entropy
]
