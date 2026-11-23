"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Termination during initialization must release the opened connection. Object subclasses represent explicit service or value boundaries.

  PuntTestPausedStore new class name
  >>> #PuntTestPausedStore
"
Class {
	#name : 'PuntTestPausedStore',
	#superclass : 'PuntTelemetryStore',
	#instVars : [
		'entered'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'accessing' }
PuntTestPausedStore >> entered [ ^ entered
]

{ #category : 'initialization' }
PuntTestPausedStore >> initialize [ super initialize. entered := Semaphore new
]

{ #category : 'private' }
PuntTestPausedStore >> prepare [ entered signal. Semaphore new wait
]
