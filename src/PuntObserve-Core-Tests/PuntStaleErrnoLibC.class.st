"
PHARO-LOG-3, PHARO-LOG-4: Deterministic stale errno after a failed exclusive open. The existing same-path descriptor must still be opened and validated.

  PuntStaleErrnoLibC new errno
  >>> 11
"
Class {
	#name : 'PuntStaleErrnoLibC',
	#superclass : 'PuntLibC',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'accessing' }
PuntStaleErrnoLibC >> errno [ ^ 11
]
