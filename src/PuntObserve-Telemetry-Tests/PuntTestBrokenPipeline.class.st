"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Provider initialization failure must close the already opened store. Object subclasses represent explicit service or value boundaries.

  PuntTestBrokenPipeline new class name
  >>> #PuntTestBrokenPipeline
"
Class {
	#name : 'PuntTestBrokenPipeline',
	#superclass : 'PuntTelemetryPipeline',
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'private' }
PuntTestBrokenPipeline >> configureProvidersFor: tool [ self error: 'Synthetic provider setup failure'
]
