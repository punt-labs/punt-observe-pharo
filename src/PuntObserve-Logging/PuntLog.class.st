"
PHARO-LOG-1, PHARO-LOG-2, PHARO-LOG-5, PHARO-LOG-6: One durable Beacon subscription per image. Entry points own start and stop; SessionManager discards snapshot state and reconstructs paths. Write failures never emit another signal.

  PuntLog new class name
  >>> #PuntLog
"
Class {
	#name : 'PuntLog',
	#superclass : 'SignalLogger',
	#instVars : [
		'sink',
		'formatter',
		'redactor',
		'threshold'
	],
	#classVars : [
		'Current',
		'Guard',
		'NoticesEnabled',
		'Role',
		'Threshold',
		'Tool'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'processes' }
PuntLog class >> childCompleted: identifier [ self work: 'child-image' outcome: #completed correlation: identifier
]

{ #category : 'processes' }
PuntLog class >> childFailed: anError correlation: identifier [ self work: 'child-image' failed: anError correlation: identifier
]

{ #category : 'processes' }
PuntLog class >> childStarted: identifier [ self work: 'child-image' outcome: #started correlation: identifier
]

{ #category : 'accessing' }
PuntLog class >> current [ ^ Current
]

{ #category : 'processes' }
PuntLog class >> fork: aBlock named: aString correlation: identifier [
 ^ self fork: aBlock named: aString correlation: identifier at: Processor userBackgroundPriority
]

{ #category : 'processes' }
PuntLog class >> fork: aBlock named: aString correlation: identifier at: priority [
 ^ [
   self work: aString outcome: #started correlation: identifier.
   [ aBlock value. self work: aString outcome: #completed correlation: identifier ]
     on: Error do: [ :error | self work: aString failed: error correlation: identifier ]
 ] forkAt: priority named: aString
]

{ #category : 'private' }
PuntLog class >> guard [ ^ Guard
]

{ #category : 'class initialization' }
PuntLog class >> initialize [ Guard := Mutex new
]

{ #category : 'testing' }
PuntLog class >> isRunning [ ^ Current notNil and: [ Current isRunning ]
]

{ #category : 'accessing' }
PuntLog class >> level: aLevel [ PuntLogLevel validate: aLevel. Threshold := aLevel. Current ifNotNil: [ Current level: aLevel ]
]

{ #category : 'accessing' }
PuntLog class >> noticesEnabled [ ^ NoticesEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
PuntLog class >> noticesEnabled: aBoolean [ NoticesEnabled := aBoolean. Current ifNotNil: [ Current sink noticesEnabled: aBoolean ]
]

{ #category : 'private' }
PuntLog class >> registerSession [
 (SessionManager default hasRegistered: self name) ifFalse: [ SessionManager default registerUserClassNamed: self name ]
]

{ #category : 'system startup' }
PuntLog class >> shutDown: quitting [
 Current ifNotNil: [ Current stop ]. Current := nil. Guard := Mutex new
]

{ #category : 'processes' }
PuntLog class >> spawnIntent: identifier [ self work: 'child-image' outcome: #spawnIntent correlation: identifier
]

{ #category : 'operating' }
PuntLog class >> startTool: aString role: aRole [
 ^ self startTool: aString role: aRole level: PuntLogLevel info
]

{ #category : 'operating' }
PuntLog class >> startTool: aString role: aRole level: aLevel [
 PuntLogLevel validate: aLevel. PuntHome validateTool: aString.
 ^ self guard critical: [
   Current := Current ifNil: [
     | logger tool |
     tool := aString copy.
     logger := self new.
     [ logger tool: tool; level: aLevel.
       self registerSession.
       logger start
     ] ifCurtailed: [ logger stop ].
     Tool := tool. Role := aRole. Threshold := aLevel.
     logger ] ]
]

{ #category : 'system startup' }
PuntLog class >> startUp: resuming [
 | tool role level |
 tool := Tool. role := Role. level := Threshold.
 Current ifNotNil: [ Current stop ]. Current := nil. Guard := Mutex new.
 tool ifNotNil: [ self startTool: tool role: role level: level ]
]

{ #category : 'registration' }
PuntLog class >> stop [
 self guard critical: [ Current ifNotNil: [ Current stop ]. Current := nil. Tool := nil. Role := nil ]
]

{ #category : 'processes' }
PuntLog class >> work: aString failed: error correlation: identifier [
 (PuntLogWorkSignal new component: aString; message: 'Background work'; outcome: #failed; correlation: identifier; error: error) emit
]

{ #category : 'processes' }
PuntLog class >> work: aString outcome: outcome correlation: identifier [
 (PuntLogWorkSignal new component: aString; message: 'Background work'; outcome: outcome; correlation: identifier) emit
]

{ #category : 'accessing' }
PuntLog >> dropCounts [ ^ sink dropCounts
]

{ #category : 'initialization' }
PuntLog >> initialize [
 super initialize. self beacon: Beacon instance.
 formatter := PuntLogFormatter new. threshold := PuntLogLevel info
]

{ #category : 'accessing' }
PuntLog >> level: aLevel [ PuntLogLevel validate: aLevel. threshold := aLevel
]

{ #category : 'utilities' }
PuntLog >> nextPut: aSignal [
 [
   (aSignal class includesBehavior: PuntLogSignal) ifTrue: [
     aSignal level >= threshold ifTrue: [
       | bytes |
       bytes := formatter format: aSignal.
       bytes := [ redactor cleanEscapedRecord: bytes ] on: Error do: [ :error | nil ].
       bytes ifNil: [ sink drop: #redactorWithhold ] ifNotNil: [ sink append: bytes ] ] ]
 ] on: Error do: [ :error | [ sink drop: #recordFailure ] on: Error do: [ :failure | nil ] ].
 ^ aSignal
]

{ #category : 'accessing' }
PuntLog >> redactor: aRedactor [ redactor := aRedactor
]

{ #category : 'accessing' }
PuntLog >> sink [ ^ sink
]

{ #category : 'accessing' }
PuntLog >> sink: aSink [ sink := aSink
]

{ #category : 'registration' }
PuntLog >> start [ self startFor: PuntLogSignal
]

{ #category : 'registration' }
PuntLog >> stop [ super stop. sink ifNotNil: [ sink close ]
]

{ #category : 'initialization' }
PuntLog >> tool: aString [
 sink := PuntLogSink new noticesEnabled: self class noticesEnabled; tool: aString.
 redactor := PuntLogRedactor new home: sink home root pathString
]
