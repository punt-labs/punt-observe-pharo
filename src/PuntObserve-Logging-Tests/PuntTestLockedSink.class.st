"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntTestLockedSink new class name
  >>> #PuntTestLockedSink
"
Class {
	#name : 'PuntTestLockedSink',
	#superclass : 'PuntLogSink',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'testing' }
PuntTestLockedSink >> hold: aBlock [ mutex critical: aBlock
]
