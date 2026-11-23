"
PHARO-LOG-6: Typed DEBUG fixture for the installed smoke, without mutable signal levels.

  PuntObserveSmokeDebugSignal level = PuntLogLevel debug
  >>> true
"
Class {
	#name : 'PuntObserveSmokeDebugSignal',
	#superclass : 'PuntLogSignal',
	#category : 'PuntObserve-Smoke',
	#package : 'PuntObserve-Smoke'
}

{ #category : 'accessing' }
PuntObserveSmokeDebugSignal class >> level [ ^ PuntLogLevel debug
]
