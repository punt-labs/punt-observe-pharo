"
PHARO-LOG-3: deterministic chmod denial and foreign-owner test adapter, without depending on the CI user being unprivileged.

  PuntFailingLibC new fchmod: -1 mode: 8r600
  >>> -1
"
Class {
	#name : 'PuntFailingLibC',
	#superclass : 'PuntLibC',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'ffi' }
PuntFailingLibC >> fchmod: aDescriptor mode: aMode [ ^ -1
]
