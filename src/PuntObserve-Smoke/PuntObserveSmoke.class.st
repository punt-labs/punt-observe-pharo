"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: PHARO-LOG-1..6 and PHARO-TEL-1..5 installed command-line acceptance entry point; owns only fixture orchestration. Object subclasses represent explicit service or value boundaries.

  PuntObserveSmoke new class name
  >>> #PuntObserveSmoke
"
Class {
	#name : 'PuntObserveSmoke',
	#superclass : 'Object',
	#instVars : [
		'role',
		'logger',
		'telemetry',
		'correlation',
		'outcome'
	],
	#category : 'PuntObserve-Smoke',
	#package : 'PuntObserve-Smoke'
}

{ #category : 'private' }
PuntObserveSmoke class >> descriptorTarget: fd [
 | bytes length |
 bytes := ByteArray new: 4096.
 length := self readLink: '/proc/self/fd/' , fd asString into: bytes count: bytes size.
 length < 0 ifTrue: [ ^ '' ].
 ^ (bytes copyFrom: 1 to: length) utf8Decoded
]

{ #category : 'ffi' }
PuntObserveSmoke class >> processId [ ^ self ffiCall: #(int getpid()) library: LibC
]

{ #category : 'ffi' }
PuntObserveSmoke class >> readLink: path into: bytes count: count [ ^ self ffiCall: #(long readlink(String path, ByteArray bytes, ulong count)) library: LibC
]

{ #category : 'running' }
PuntObserveSmoke class >> runRole: aRole records: count fail: failing spawn: spawning [
 Smalltalk exit: (self new runRole: aRole records: count fail: failing spawn: spawning)
]

{ #category : 'ffi' }
PuntObserveSmoke class >> sessionId [ ^ self sessionOf: 0
]

{ #category : 'ffi' }
PuntObserveSmoke class >> sessionOf: pid [ ^ self ffiCall: #(int getsid(int pid)) library: LibC
]

{ #category : 'accessing' }
PuntObserveSmoke class >> tool [ ^ 'punt-observe-smoke'
]

{ #category : 'private' }
PuntObserveSmoke >> awaitBarrier [
 | ready go |
 ready := self environment: 'PUNT_SMOKE_READY' default: ''.
 ready ifEmpty: [ ^ self ].
 ready asFileReference writeStreamDo: [ :stream | stream nextPutAll: 'ready' ].
 go := (self environment: 'PUNT_SMOKE_GO' default: '') asFileReference.
 self waitUntil: [ go exists ]
]

{ #category : 'private' }
PuntObserveSmoke >> component [ ^ 'smoke-' , role
]

{ #category : 'private' }
PuntObserveSmoke >> drainTelemetry [
 telemetry isEnabled ifTrue: [ self waitUntil: [ telemetry queue isEmpty ] ]
]

{ #category : 'private' }
PuntObserveSmoke >> environment: key default: fallback [ ^ OSEnvironment current at: key ifAbsent: [ fallback ]
]

{ #category : 'private' }
PuntObserveSmoke >> exerciseRecords: count fail: failing spawn: spawning [
 self awaitBarrier.
 self logOutcome: #started.
 role = 'child' ifTrue: [ PuntLog childStarted: correlation ].
 self fixture.
 self writeRecords: count.
 spawning ifTrue: [ self spawnChild ].
 failing ifTrue: [ self error: 'Deliberate smoke failure' ]
]

{ #category : 'private' }
PuntObserveSmoke >> finish [
 self logOutcome: outcome. self fixture.
 role = 'child' ifTrue: [ outcome = #ok
   ifTrue: [ PuntLog childCompleted: correlation ]
   ifFalse: [ PuntLog childFailed: Error new correlation: correlation ] ].
 [ self recordTelemetry. self drainTelemetry ] ensure: [ PuntTelemetry shutdown ].
 self writeReport. PuntLog stop.
 role = 'child' ifTrue: [
   (self environment: 'PUNT_SMOKE_CHILD_DONE' default: '') ifNotEmpty: [ :path |
     path asFileReference writeStreamDo: [ :stream | stream nextPutAll: 'complete' ] ] ]
]

{ #category : 'private' }
PuntObserveSmoke >> fixture [
 (PuntLogSecuritySignal new component: self component;
   message: ('https://fixture-user:fixture-pass@fixture.example.invalid/private?token=fixture-query#fixture-fragment Bearer FIXTURE-BEARER-SECRET smoke.customer@example.invalid '
     , (String with: (Character value: 27)) , '[31m forged' , String lf , 'line' , (String with: (Character value: 8238)))) emit
]

{ #category : 'private' }
PuntObserveSmoke >> logOutcome: aSymbol [
 (PuntLogWorkSignal new component: self component; message: 'Smoke run'; correlation: correlation; outcome: aSymbol) emit
]

{ #category : 'private' }
PuntObserveSmoke >> recordTelemetry [
 | admitted |
 admitted := { PuntTelemetry record: (PuntObserveSmokeSpan new outcome: outcome; subject: 'smoke-raw-subject-identifier'; duration: 1; yourself).
   PuntTelemetry record: PuntObserveSmokeEvent new.
   PuntTelemetry record: PuntObserveSmokeCounter new }.
 (telemetry isEnabled and: [ admitted includes: false ]) ifTrue: [ self error: 'Smoke telemetry admission failed' ]
]

{ #category : 'private' }
PuntObserveSmoke >> reportFile [
 ^ (self environment: 'PUNT_SMOKE_REPORT' default: (FileLocator home / 'punt-observe-smoke-result.json') pathString) asFileReference
]

{ #category : 'running' }
PuntObserveSmoke >> runRole: aRole records: count fail: failing spawn: spawning [
 role := aRole. outcome := #ok.
 correlation := self environment: 'PUNT_SMOKE_CORRELATION' default: 'smoke-correlation'.
 self start.
 [ [ self exerciseRecords: count fail: failing spawn: spawning ]
     on: Error do: [ :error | outcome := #failed. (PuntLogErrorSignal new component: self component; message: 'Smoke operation failed'; error: error) emit ]
 ] ensure: [ self finish ].
 ^ outcome = #ok ifTrue: [ 0 ] ifFalse: [ 1 ]
]

{ #category : 'private' }
PuntObserveSmoke >> shellQuote: text [
 | quote escaped |
 quote := String with: $'.
 escaped := String withAll: { $'. $". $'. $". $' }.
 ^ quote , (text copyReplaceAll: quote with: escaped) , quote
]

{ #category : 'private' }
PuntObserveSmoke >> spawnChild [
 | marker report command |
 marker := self reportFile pathString , '.child.done'.
 report := self reportFile pathString , '.child.json'.
 PuntLog spawnIntent: correlation.
 command := 'PUNT_SMOKE_CHILD_DONE=' , (self shellQuote: marker) , ' PUNT_SMOKE_REPORT=' , (self shellQuote: report)
   , ' setsid ' , (self shellQuote: Smalltalk vm fullPath) , ' --headless ' , (self shellQuote: Smalltalk imagePath)
   , ' --no-default-preferences eval ' , (self shellQuote: 'PuntObserveSmoke runRole: ''child'' records: 0 fail: false spawn: false')
   , ' </dev/null >/dev/null 2>&1 &'.
 LibC resultOfCommand: command.
 self waitUntil: [ marker asFileReference exists ].
 ((STONJSON fromString: report asFileReference contents) at: 'outcome') = 'ok' ifFalse: [ self error: 'Smoke child failed' ]
]

{ #category : 'private' }
PuntObserveSmoke >> start [
 | config |
 PuntLog noticesEnabled: true.
 logger := PuntLog startTool: self class tool role: role level: PuntLogLevel debug.
 config := PuntTelemetryConfig new disabled: ((self environment: 'PUNT_SMOKE_CONFIG_DISABLED' default: '0') = '1').
 telemetry := PuntTelemetry startTool: self class tool config: config schemas: { PuntObserveSmokeSpan. PuntObserveSmokeEvent. PuntObserveSmokeCounter }
]

{ #category : 'private' }
PuntObserveSmoke >> waitUntil: aBlock [
 | started |
 started := Time millisecondClockValue.
 [ aBlock value ] whileFalse: [
   (Time millisecondsSince: started) > 15000 ifTrue: [ self error: 'Smoke wait timed out' ].
   (Delay forMilliseconds: 10) wait ]
]

{ #category : 'private' }
PuntObserveSmoke >> writeRecords: count [
 | payload |
 payload := String streamContents: [ :stream | 500 timesRepeat: [ stream nextPutAll: (String new: 93 withAll: $p); space ] ].
 1 to: count do: [ :index |
   (PuntObserveSmokeDebugSignal new component: 'writer';
     message: (String streamContents: [ :stream |
       stream nextPutAll: 'TAG-'; nextPutAll: role; nextPut: $-; print: index; space;
         nextPutAll: payload; nextPutAll: 'END-'; nextPutAll: role; nextPut: $-; print: index ])) emit ]
]

{ #category : 'private' }
PuntObserveSmoke >> writeReport [
 | report |
 report := Dictionary newFrom: {
   'role' -> role. 'outcome' -> outcome asString. 'correlation' -> correlation.
   'process_id' -> self class processId. 'stdio' -> (#(0 1 2) collect: [ :fd | self class descriptorTarget: fd ]). 'session_id' -> self class sessionId.
   'worker_stopped' -> telemetry worker isNil. 'telemetry_enabled' -> telemetry queue notNil.
   'telemetry_dropped' -> telemetry dropped.
   'log_drops' -> (Dictionary newFrom: (logger dropCounts associations collect: [ :pair | pair key asString -> pair value ])) }.
 self reportFile writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: report) ]
]
