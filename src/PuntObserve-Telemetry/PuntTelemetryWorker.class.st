"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: The sole low-priority owner of private providers and SQLite; idle collection, expiry and bounded shutdown. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryWorker new class name
  >>> #PuntTelemetryWorker
"
Class {
	#name : 'PuntTelemetryWorker',
	#superclass : 'Object',
	#instVars : [
		'queue',
		'pipeline',
		'process',
		'stopping',
		'aborted',
		'home',
		'config',
		'lastMaintenance',
		'lastCollection'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'private' }
PuntTelemetryWorker >> collectIfDue [
 (Time millisecondsSince: lastCollection) < 1000 ifTrue: [ ^ self ].
 lastCollection := Time millisecondClockValue.
 pipeline ifNil: [ self setup ] ifNotNil: [ self safely: [ pipeline collect ] ].
 queue dropped > 0 ifTrue: [ PuntTelemetryDiagnostics noteFailure ]
]

{ #category : 'accessing' }
PuntTelemetryWorker >> pipeline [ ^ pipeline
]

{ #category : 'accessing' }
PuntTelemetryWorker >> process [ ^ process
]

{ #category : 'private' }
PuntTelemetryWorker >> pruneIfDue [
 (Time millisecondsSince: lastMaintenance) < (config maintenanceSeconds * 1000) ifTrue: [ ^ self ].
 lastMaintenance := Time millisecondClockValue. pipeline ifNotNil: [ self safely: [ pipeline prune ] ]
]

{ #category : 'initialization' }
PuntTelemetryWorker >> queue: aQueue home: aHome config: aConfig [
 queue := aQueue. home := aHome. config := aConfig. stopping := false. aborted := false.
 lastMaintenance := Time millisecondClockValue. lastCollection := lastMaintenance.
 ^ self
]

{ #category : 'private' }
PuntTelemetryWorker >> run [
 [ stopping ifFalse: [ self setup ].
   [ stopping and: [ queue isEmpty ] ] whileFalse: [ self step ].
   pipeline ifNotNil: [ self safely: [ pipeline collect ] ]
 ] ensure: [ pipeline ifNotNil: [ aborted ifTrue: [ pipeline abort ] ifFalse: [ self safely: [ pipeline close ] ] ] ]
]

{ #category : 'private' }
PuntTelemetryWorker >> safely: aBlock [
 [ aBlock value ] on: Error do: [ :error | PuntTelemetryDiagnostics noteFailure ]
]

{ #category : 'private' }
PuntTelemetryWorker >> setup [
 [ pipeline := PuntTelemetryPipeline new home: home config: config ]
   on: Error do: [ :error | pipeline := nil. PuntTelemetryDiagnostics noteFailure ]
]

{ #category : 'operating' }
PuntTelemetryWorker >> shutdown [
 | started |
 stopping := true. queue close. started := Time millisecondClockValue.
 process ifNotNil: [
   [ process isTerminated not and: [ (Time millisecondsSince: started) < 1900 ] ] whileTrue: [ (Delay forMilliseconds: 5) wait ].
   process isTerminated ifFalse: [ aborted := true. process terminate. PuntTelemetryDiagnostics noteFailure ] ].
 queue discard > 0 ifTrue: [ PuntTelemetryDiagnostics noteFailure ]. pipeline := nil. process := nil
]

{ #category : 'operating' }
PuntTelemetryWorker >> start [
 process := [ self run ] forkAt: Processor userBackgroundPriority named: 'Punt telemetry worker'.
 ^ self
]

{ #category : 'private' }
PuntTelemetryWorker >> step [
 | record |
 record := queue pop.
 record ifNotNil: [ pipeline ifNil: [ queue drop ] ifNotNil: [ self safely: [ pipeline record: record ] ] ].
 self collectIfDue. self pruneIfDue.
 record ifNil: [ queue wait ]
]
