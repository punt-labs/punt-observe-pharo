"
PHARO-LOG-5: WARNING diagnostic for a security decision without rejected content.

  PuntLogSecuritySignal new class name
  >>> #PuntLogSecuritySignal
"
Class {
	#name : 'PuntLogSecuritySignal',
	#superclass : 'PuntLogSignal',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'accessing' }
PuntLogSecuritySignal class >> level [ ^ PuntLogLevel warning
]
