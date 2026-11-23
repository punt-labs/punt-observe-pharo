"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior. Object is the service or value boundary.

  PuntTestBrokenSink new class name
  >>> #PuntTestBrokenSink
"
Class {
	#name : 'PuntTestBrokenSink',
	#superclass : 'Object',
	#instVars : [
		'calls'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'operating' }
PuntTestBrokenSink >> append: bytes [ calls := self calls + 1. self error: 'Sink unavailable'
]

{ #category : 'accessing' }
PuntTestBrokenSink >> calls [ ^ calls ifNil: [ 0 ]
]

{ #category : 'operating' }
PuntTestBrokenSink >> close [
]
