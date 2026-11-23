"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: PHARO-LOG-3/4: failed metadata must not hide an existing regular file or dangling symlink. Object subclasses represent explicit service or value boundaries.

  PuntTestBrokenStatLibC new class name
  >>> #PuntTestBrokenStatLibC
"
Class {
	#name : 'PuntTestBrokenStatLibC',
	#superclass : 'PuntLibC',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntTestBrokenStatLibC >> stat: path [ PuntPermissionError signal: 'Synthetic metadata failure'
]
