"
Private atomic loss counter backed by the inherited Semaphore signal primitive. No process waits on this semaphore.

  (PuntTelemetryDropCounter new signal; count)
  >>> 1
"
Class {
	#name : 'PuntTelemetryDropCounter',
	#superclass : 'Semaphore',
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'accessing' }
PuntTelemetryDropCounter >> count [ ^ excessSignals
]
