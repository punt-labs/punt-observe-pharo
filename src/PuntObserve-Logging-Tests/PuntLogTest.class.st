"
PHARO-LOG-1, PHARO-LOG-2, PHARO-LOG-5, PHARO-LOG-6: Acceptance fixture for PHARO-LOG-1, PHARO-LOG-2, PHARO-LOG-5, PHARO-LOG-6; deterministic isolation of logging behavior.

  PuntLogTest new class name
  >>> #PuntLogTest
"
Class {
	#name : 'PuntLogTest',
	#superclass : 'PuntHomeTest',
	#instVars : [
		'logger'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'private' }
PuntLogTest >> contents [ ^ logger sink home logFile contents
]

{ #category : 'private' }
PuntLogTest >> emit: text [
 (PuntLogSignal new component: 'test'; message: text) emit
]

{ #category : 'running' }
PuntLogTest >> setUp [ super setUp. PuntLog stop
]

{ #category : 'private' }
PuntLogTest >> start [
 logger := PuntHome duringHome: home do: [ PuntLog startTool: 'sample-tool' role: 'test' ].
 PuntLog noticesEnabled: false.
 ^ logger
]

{ #category : 'private' }
PuntLogTest >> subscriptionsFor: subscriber [
 | count |
 count := 0.
 Beacon instance announcer subscriptions subscriptionsOf: subscriber do: [ :each | count := count + 1 ].
 ^ count
]

{ #category : 'running' }
PuntLogTest >> tearDown [ PuntLog stop. super tearDown
]

{ #category : 'tests' }
PuntLogTest >> testDropAccountingIsCategorizedAndNonRecursive [
 | sink |
 self start. sink := logger sink.
 self assert: (logger dropCounts values allSatisfy: [ :count | count = 0 ]).
 logger redactor: PuntTestFailingRedactor new.
 self emit: 'withheld'.
 self assert: (logger dropCounts at: #redactorWithhold) equals: 1.
 logger redactor: (PuntLogRedactor new home: home pathString).
 sink libc: (PuntTestWriteFailureLibC new kind: #shortWrite).
 self emit: 'short'.
 self assert: (logger dropCounts at: #shortWrite) equals: 1.
 sink libc: (PuntTestWriteFailureLibC new kind: #ioFailure).
 self emit: 'failed'.
 self assert: (logger dropCounts at: #ioFailure) equals: 1.
 self assert: sink noticeCount equals: 1.
 self assert: self contents isEmpty.
 sink libc: PuntLibC new.
 self emit: 'recovered'.
 self assert: (self contents includesSubstring: 'recovered').
 self assert: logger dropCounts values sum equals: 3
]

{ #category : 'tests' }
PuntLogTest >> testFailuresAreWithheldAndNonRecursive [
 | broken |
 self start.
 logger redactor: PuntTestFailingRedactor new.
 self emit: 'Must be withheld'.
 self assert: self contents isEmpty.
 logger redactor: PuntLogRedactor new.
 broken := PuntTestBrokenSink new.
 logger sink: broken.
 self emit: 'Failed write'.
 self assert: broken calls equals: 1
]

{ #category : 'tests' }
PuntLogTest >> testForkOutcomesAreCorrelated [
 | first second |
 self start.
 first := PuntLog fork: [ 1 + 1 ] named: 'worker' correlation: 'good-id'.
 second := PuntLog fork: [ self error: 'PRIVATE-FAILURE' ] named: 'worker' correlation: 'bad-id'.
 self waitFor: [ first isTerminated and: [ second isTerminated ] ].
 self assert: (self contents includesSubstring: 'correlation=good-id outcome=started').
 self assert: (self contents includesSubstring: 'correlation=good-id outcome=completed').
 self assert: (self contents includesSubstring: 'correlation=bad-id outcome=failed errorClass=Error').
 self deny: (self contents includesSubstring: 'PRIVATE-FAILURE')
]

{ #category : 'tests' }
PuntLogTest >> testFormatLevelsAndForgedLines [
 self start.
 (PuntLogDebugSignal new message: 'Hidden debug') emit.
 (PuntLogSecuritySignal new component: 'security'; message: 'Rejected token') emit.
 self emit: 'Line' , String lf , 'FORGED'.
 self assert: self contents lines size equals: 2.
 self deny: (self contents includesSubstring: 'Hidden debug').
 self assert: (self contents includesSubstring: '[WARNING] security: Rejected token').
 self assert: (self contents includesSubstring: 'Line\x0aFORGED').
 self assert: (self contents lines first matchesRegex: '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\:[0-9]{2}\:[0-9]{2} \[WARNING\] security\: Rejected token').
 PuntLog level: PuntLogLevel debug.
 (PuntLogDebugSignal new message: 'Visible debug') emit.
 self assert: (self contents includesSubstring: '[DEBUG]')
]

{ #category : 'tests' }
PuntLogTest >> testOnlyTypedSignalsAndSafeErrorFields [
 self start.
 'x' emit.
 'WRAPPED-SECRET-x' emit.
 (PuntTestFieldSignal new message: 'Object withheld'; detail: PuntTestUnsafeObject new) emit.
 (PuntTestFieldSignal new message: 'password=FIELD-SECRET https://user:pass@example.test/private?q=secret'; detail: 'Bearer TOKEN-SECRET') emit.
 (PuntTestFieldSignal new message: 'Escaped spacing'; detail: 'Bearer' , String lf , 'CONTROL-TOKEN-SECRET') emit.
 (PuntLogErrorSignal new message: 'Operation failed'; error: (Error new messageText: 'ERROR-SECRET')) emit.
 self deny: (self contents includesSubstring: 'WRAPPED-SECRET').
 self deny: (self contents includesSubstring: 'FIELD-SECRET').
 self deny: (self contents includesSubstring: 'TOKEN-SECRET').
 self deny: (self contents includesSubstring: 'CONTROL-TOKEN-SECRET').
 self deny: (self contents includesSubstring: 'ERROR-SECRET').
 self deny: (self contents includesSubstring: 'example.test').
 self deny: (self contents includesSubstring: 'signalerContext').
 self deny: (self contents includesSubstring: 'PRIVATE-OBJECT-CONTENT').
 self deny: (self contents includesSubstring: ': x').
 self assert: (self contents includesSubstring: 'errorClass=Error')
]

{ #category : 'tests' }
PuntLogTest >> testRepeatedStartAndStop [
 self start.
 5 timesRepeat: [ self assert: (PuntLog startTool: 'sample-tool' role: 'test') identicalTo: logger ].
 self assert: PuntLog isRunning.
 self assert: (self subscriptionsFor: logger) equals: 1.
 self emit: 'One record'.
 self assert: self contents lines size equals: 1.
 PuntLog stop.
 self deny: PuntLog isRunning.
 self assert: (self subscriptionsFor: logger) equals: 0
]

{ #category : 'tests' }
PuntLogTest >> testReusableSourceGate [
 | gate |
 gate := PuntLogSourceGate.
 #(nestedTranscript nestedLogger nestedZinc standardOutput zincAnnouncer) do: [ :selector |
   self assert: (gate forbidden: (PuntTestForbiddenLogger >> selector)) ].
 self assert: (gate violationsInPackages: #('PuntObserve-Core') allowing: #()) isEmpty.
 self deny: (gate violationsInPackages: #('PuntObserve-Logging') allowing: #()) isEmpty.
 self assert: (gate violationsInPackages: #('PuntObserve-Logging') allowing: #(PuntLog PuntLogSink PuntLogZincBridge PuntLogSourceGate)) isEmpty
]

{ #category : 'tests' }
PuntLogTest >> testSessionResolvesChangedHome [
 | changed original |
 self start. original := logger sink home logFile.
 self emit: 'Original session'.
 changed := sandbox / 'changed-home'. changed ensureCreateDirectory.
 PuntLog shutDown: false.
 PuntHome duringHome: changed do: [ PuntLog startUp: true ].
 logger := PuntLog current.
 self deny: logger sink noticesEnabled.
 self emit: 'New session'.
 self assert: logger sink home logFile equals: changed / '.punt-labs' / 'sample-tool' / 'logs' / 'sample-tool.log'.
 self assert: (original contents includesSubstring: 'Original session').
 self deny: (original contents includesSubstring: 'New session').
 self assert: (self contents includesSubstring: 'New session')
]

{ #category : 'tests' }
PuntLogTest >> testSinkCapsAndUnicodeControls [
 self start.
 self emit: ('a ' repeat: 32700).
 self assert: self contents utf8Encoded size <= 65536.
 self emit: ('b' repeat: 65536).
 self assert: self contents lines size equals: 1.
 self emit: ((Character value: 16r85) asString , (Character value: 16r2029) asString , (Character value: 16r2066) asString).
 self assert: self contents lines size equals: 2.
 self assert: (self contents includesSubstring: '\x85\u2029\u2066')
]

{ #category : 'tests' }
PuntLogTest >> testZincBridgeOwnedAndIdempotent [
 | bridge count |
 self start. PuntLog level: PuntLogLevel debug.
 bridge := PuntLogZincBridge new.
 [ bridge start; start.
   count := 0.
   ZnLogEvent announcer subscriptions subscriptionsOf: bridge do: [ :each | count := count + 1 ].
   self assert: count equals: 1.
   bridge receive: ZnLogEvent new.
   self assert: (self contents includesSubstring: '[DEBUG] zinc: ZnLogEvent')
 ] ensure: [ bridge stop ].
 count := 0.
 ZnLogEvent announcer subscriptions subscriptionsOf: bridge do: [ :each | count := count + 1 ].
 self assert: count equals: 0
]

{ #category : 'private' }
PuntLogTest >> waitFor: condition [
 | started |
 started := Time millisecondClockValue.
 [ condition value ] whileFalse: [
   self assert: (Time millisecondsSince: started) < 5000.
   (Delay forMilliseconds: 10) wait ]
]
