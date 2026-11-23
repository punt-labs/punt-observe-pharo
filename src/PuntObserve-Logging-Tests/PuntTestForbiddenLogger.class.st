"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntTestForbiddenLogger new class name
  >>> #PuntTestForbiddenLogger
"
Class {
	#name : 'PuntTestForbiddenLogger',
	#superclass : 'SignalLogger',
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'testing' }
PuntTestForbiddenLogger >> nestedLogger [ ^ [ PuntLog ]
]

{ #category : 'testing' }
PuntTestForbiddenLogger >> nestedTranscript [ ^ [ Transcript ]
]

{ #category : 'testing' }
PuntTestForbiddenLogger >> nestedZinc [ ^ [ ZnLogEvent announcer ]
]

{ #category : 'testing' }
PuntTestForbiddenLogger >> standardOutput [ ^ Stdio stdout
]

{ #category : 'testing' }
PuntTestForbiddenLogger >> zincAnnouncer [ ^ ZnLogEvent announcer
]
