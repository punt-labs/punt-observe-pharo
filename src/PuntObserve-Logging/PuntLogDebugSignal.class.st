"
PHARO-LOG-6: DEBUG diagnostic for explicitly enabled transport and housekeeping events.

  PuntLogDebugSignal new class name
  >>> #PuntLogDebugSignal
"
Class {
	#name : 'PuntLogDebugSignal',
	#superclass : 'PuntLogSignal',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogDebugSignal class >> level [ ^ PuntLogLevel debug
]
