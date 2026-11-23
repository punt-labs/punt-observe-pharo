"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Isolated telemetry acceptance fixture. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryTest new class name
  >>> #PuntTelemetryTest
"
Class {
	#name : 'PuntTelemetryTest',
	#superclass : 'PuntHomeTest',
	#instVars : [
		'telemetry',
		'store',
		'environment'
	],
	#category : 'PuntObserve-Telemetry-Tests',
	#package : 'PuntObserve-Telemetry-Tests'
}

{ #category : 'ffi' }
PuntTelemetryTest class >> makeFifo: path mode: mode [ ^ self ffiCall: #(int mkfifo(String path, int mode)) library: LibC
]

{ #category : 'private' }
PuntTelemetryTest >> observation [ ^ PuntTestObservation new outcome: #ok; identifier: 'PRIVATE-CUSTOMER-ID'; items: 3; enabled: true; yourself
]

{ #category : 'private' }
PuntTelemetryTest >> recordEventually: observation [
 | admitted |
 admitted := false.
 self waitUntil: [ admitted ifFalse: [ admitted := telemetry record: observation ]. admitted ].
 ^ admitted
]

{ #category : 'private' }
PuntTelemetryTest >> rows [
 | db |
 db := PuntTelemetryConnection openOn: (home / '.punt-labs' / 'sample-tool' / 'telemetry.db') pathString.
 ^ [ db execute: 'SELECT * FROM signals ORDER BY end_ns' with: #() doing: [ :cursor | cursor rows ] ] ensure: [ db forceClose ]
]

{ #category : 'private' }
PuntTelemetryTest >> schemas [ ^ { PuntTestObservation. PuntTestEvent. PuntTestCounter. PuntTestHistogram }
]

{ #category : 'running' }
PuntTelemetryTest >> setUp [ super setUp. PuntTelemetry shutdown. environment := OSEnvironment current
]

{ #category : 'private' }
PuntTelemetryTest >> start: config [
 telemetry := PuntHome duringHome: home do: [ PuntTelemetry startTool: 'sample-tool' config: config schemas: self schemas ].
 self waitUntil: [ telemetry worker pipeline notNil ].
 ^ telemetry
]

{ #category : 'running' }
PuntTelemetryTest >> tearDown [ PuntTelemetry shutdown. telemetry ifNotNil: [ telemetry shutdown ]. store ifNotNil: [ store close ]. super tearDown
]

{ #category : 'tests' }
PuntTelemetryTest >> testConcurrentDropsNeverWaitOnQueueMutex [
 | queue lock done processes |
 queue := PuntTelemetryQueue new. lock := queue instVarNamed: 'mutex'. done := Semaphore new.
 processes := OrderedCollection new.
 [ lock critical: [
     8 timesRepeat: [ processes add: [
       [ 2000 timesRepeat: [ queue push: #rejected. Processor yield ] ] ensure: [ done signal ] ] fork ].
     8 timesRepeat: [ self deny: (done waitTimeoutMilliseconds: 5000) ] ].
   self assert: queue dropped equals: 16000.
   self assert: queue isEmpty.
   queue close. self deny: (queue push: #closed).
   self assert: queue dropped equals: 16001
 ] ensure: [ processes do: [ :process | process terminate ] ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testConfigurationBoundsAndConsent [
 #(0 -1 3651 1.5) do: [ :days | self should: [ (PuntTelemetryConfig new retentionDays: days) validatedCopy ] raise: Error ].
 #('http://example.test' 'http://localhost' 'ftp://127.0.0.1' 'https://user:password@example.test' 'https://example.test/?token=secret') do: [ :endpoint |
   self should: [ (PuntTelemetryConfig new otlpEndpoint: endpoint) validatedCopy ] raise: Error ].
 self deny: (PuntTelemetryConfig new otlpEndpoint: 'https://example.test'; validatedCopy; usesOtlp).
 self assert: (PuntTelemetryConfig new otlpConsent: true; otlpEndpoint: 'http://127.0.0.1:9999'; validatedCopy; usesOtlp)
]

{ #category : 'tests' }
PuntTelemetryTest >> testConfigurationOwnsEndpointSnapshot [
 | endpoint config snapshot |
 endpoint := 'http://127.0.0.1:4318' copy.
 config := PuntTelemetryConfig new otlpConsent: true; otlpEndpoint: endpoint.
 snapshot := config validatedCopy.
 endpoint at: 8 put: $e.
 self assert: snapshot otlpEndpoint equals: 'http://127.0.0.1:4318'.
 self should: [ config validatedCopy ] raise: Error
]

{ #category : 'tests' }
PuntTelemetryTest >> testConnectionFinalizationIsExactlyOnce [
 | db handle |
 db := PuntTelemetryConnection memory.
 db open. handle := db handle.
 self assert: (FFIExternalResourceManager uniqueInstance includes: handle).
 db forceClose.
 self deny: (FFIExternalResourceManager uniqueInstance includes: handle).
 self assert: handle isNull.
 db forceClose
]

{ #category : 'tests' }
PuntTelemetryTest >> testDiagnosticsAreFixedAndRateLimited [
 | signals |
 signals := OrderedCollection new.
 self start: PuntTelemetryConfig new.
 telemetry worker pipeline spanExporter delegate: PuntTestFailingSpanExporter new.
 PuntTelemetryDiagnostics resetSession.
 Beacon instance announcer when: PuntLogSignal do: [ :signal | signals add: signal ] for: signals.
 [ 10 timesRepeat: [ self recordEventually: self observation ].
   self waitUntil: [ signals size = 1 ].
   self assert: signals size equals: 1.
   self assert: signals first message equals: 'Telemetry operation dropped or failed'.
   self deny: (signals first printString includesSubstring: 'PRIVATE')
 ] ensure: [ Beacon instance unsubscribe: signals ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testDiscardCountsEveryQueuedRecord [
 | queue |
 queue := PuntTelemetryQueue new.
 self assert: queue discard equals: 0.
 3 timesRepeat: [ self assert: (queue push: #record) ].
 queue close.
 self assert: queue discard equals: 3.
 self assert: queue dropped equals: 3.
 self assert: queue discard equals: 0.
 self assert: queue dropped equals: 3
]

{ #category : 'tests' }
PuntTelemetryTest >> testEveryVetoAndSessionReread [
 | previous |
 #('PUNT_TELEMETRY' 'SAMPLE_TOOL_TELEMETRY') do: [ :key |
   previous := environment at: key ifAbsent: [ nil ].
   [ environment at: key put: 'off'.
     telemetry := PuntHome duringHome: home do: [ PuntTelemetry startTool: 'sample-tool' config: PuntTelemetryConfig new schemas: self schemas ].
     self deny: telemetry isEnabled. self assert: telemetry worker isNil.
     self deny: (home / '.punt-labs') exists.
     self deny: (telemetry record: self observation).
     environment at: key put: 'on'.
     PuntHome duringHome: home do: [ PuntTelemetry startUp: true ].
     self assert: PuntTelemetry current isEnabled.
     PuntTelemetry shutdown.
     (home / '.punt-labs') ensureDeleteAll
   ] ensure: [ previous ifNil: [ environment removeKey: key ] ifNotNil: [ environment at: key put: previous ]. PuntTelemetry shutdown ] ].
 telemetry := PuntHome duringHome: home do: [ PuntTelemetry startTool: 'sample-tool' config: (PuntTelemetryConfig new disabled: true) schemas: self schemas ].
 self deny: telemetry isEnabled. self assert: telemetry worker isNil. self deny: (home / '.punt-labs') exists
]

{ #category : 'tests' }
PuntTelemetryTest >> testExporterFailureAndBoundedShutdown [
 | stalled started |
 self start: PuntTelemetryConfig new.
 telemetry worker pipeline spanExporter delegate: PuntTestFailingSpanExporter new.
 self recordEventually: self observation.
 self waitUntil: [ telemetry queue isEmpty ].
 self deny: telemetry worker process isTerminated.
 stalled := PuntTestStalledSpanExporter new.
 telemetry worker pipeline spanExporter delegate: stalled.
 self recordEventually: self observation.
 stalled entered wait.
 started := Time millisecondClockValue.
 [ telemetry shutdown. self assert: (Time millisecondsSince: started) < 2300 ] ensure: [ stalled release ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testExporterShutdownPreservesDelegateResults [
 { PuntTelemetrySpanExporter -> OTSpanExporter. PuntTelemetryMetricExporter -> OTMetricExporter } do: [ :classes |
   | exporter |
   exporter := classes key new delegate: classes value new.
   self assert: exporter shutdown identicalTo: true.
   self assert: exporter shutdown identicalTo: false ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testFacadeSaturationDoesNotWaitForExporter [
 | stalled observation started |
 self start: PuntTelemetryConfig new.
 stalled := PuntTestStalledSpanExporter new.
 telemetry worker pipeline spanExporter delegate: stalled.
 observation := self observation identifier: nil.
 self recordEventually: observation. stalled entered wait.
 [ 1024 timesRepeat: [ self assert: (telemetry record: observation) ].
   started := Time millisecondClockValue.
   self deny: (telemetry record: observation).
   self assert: (Time millisecondsSince: started) < 100.
   self assert: telemetry queue size equals: 1024
 ] ensure: [ stalled release. telemetry shutdown ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testForcedShutdownCountsQueueAndNoticesInterruption [
 | stalled worker signals |
 self start: PuntTelemetryConfig new.
 stalled := PuntTestStalledSpanExporter new.
 worker := telemetry worker.
 worker pipeline spanExporter delegate: stalled.
 self recordEventually: (self observation identifier: nil). self deny: (stalled entered waitTimeoutMilliseconds: 5000).
 3 timesRepeat: [ self assert: (telemetry record: (self observation identifier: nil)) ].
 signals := OrderedCollection new. PuntTelemetryDiagnostics resetSession.
 Beacon instance announcer when: PuntLogSignal do: [ :signal | signals add: signal ] for: signals.
 [ telemetry shutdown.
   self assert: telemetry dropped equals: 3.
   self assert: telemetry queue isEmpty.
   self assert: worker process isNil.
   self assert: signals size equals: 1
 ] ensure: [ stalled release. Beacon instance unsubscribe: signals ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testIdentifierBounds [
 | field |
 field := PuntTelemetryField kind: #identifier required: true.
 self assert: (field accepts: '').
 self assert: (field accepts: (String new: 65536 withAll: $a)).
 self deny: (field accepts: (String new: 65537 withAll: $a)).
 self assert: (field accepts: (WideString new: 32768 withAll: (Character value: 256))).
 self deny: (field accepts: (WideString new: 32769 withAll: (Character value: 256)))
]

{ #category : 'tests' }
PuntTelemetryTest >> testLateSaltPublisherIsRetriedOnce [
 | paths reader bytes |
 paths := PuntHome duringHome: home do: [ (PuntHome forTool: 'sample-tool') ensureDirectories ].
 reader := PuntTestLatePublishedSalt new.
 bytes := reader readAt: paths.
 self assert: reader attempts equals: 2.
 self assert: bytes size equals: 32.
 self assert: bytes equals: (PuntTelemetrySalt new readAt: paths).
 self assert: (libc stat: paths saltFile pathString) permissions equals: 8r600
]

{ #category : 'tests' }
PuntTelemetryTest >> testMetricOverflowSkipsOnlyTheInvalidPoint [
 | paths exporter now point valid overflow metric snapshot |
 paths := PuntHome duringHome: home do: [ (PuntHome forTool: 'sample-tool') ensureDirectories ].
 store := PuntTelemetryStore new home: paths retentionDays: 30.
 exporter := PuntSQLiteMetricExporter new store: store.
 now := DateAndTime now.
 point := [ :attributes | OTNumberDataPoint attributes: attributes value: 1 startTimestamp: now timestamp: now ].
 valid := point value: (Dictionary newFrom: { 'punt.schema.version' -> 1 }).
 overflow := point value: (Dictionary newFrom: { 'otel.metric.overflow' -> true }).
 metric := OTSumMetricData new name: 'test.counter'; unit: '1'; points: { valid. overflow. valid }; yourself.
 snapshot := OTMetricSnapshot empty metrics: { metric }; yourself.
 self assert: (exporter export: snapshot).
 self assert: exporter dropped equals: 1.
 self assert: self rows size equals: 2.
 self assert: (self rows allSatisfy: [ :row | (row at: 3) = 1 ]).
 self assert: (exporter export: OTMetricSnapshot empty).
 self assert: exporter dropped equals: 1.
 self assert: self rows size equals: 2.
 store close.
 self deny: (exporter export: snapshot)
]

{ #category : 'tests' }
PuntTelemetryTest >> testOtlpOnlyExplicitConfigWithHashedPayload [
 | server payloads config hash |
 payloads := SharedQueue new.
 server := ZnServer startOn: 0.
 [ server delegate: (ZnValueDelegate with: [ :request |
     payloads nextPut: request entity bytes.
     ZnResponse ok: (ZnEntity bytes: #[] ) ]).
   config := PuntTelemetryConfig new otlpConsent: true; otlpEndpoint: 'http://127.0.0.1:' , server serverSocket localPort asString.
   self start: config.
   self assert: telemetry worker pipeline spanExporter delegate class equals: OTOtlpHttpProtobufSpanExporter.
   self recordEventually: self observation.
   self recordEventually: (PuntTestCounter new outcome: #ok; identifier: 'PRIVATE-CUSTOMER-ID').
   telemetry shutdown.
   self deny: telemetry home databaseFile exists.
   self assert: payloads size >= 2.
   hash := PuntTelemetrySalt new hash: 'PRIVATE-CUSTOMER-ID' home: telemetry home.
   [ payloads isEmpty ] whileFalse: [ | bytes | bytes := payloads next asString.
     self deny: (bytes includesSubstring: 'PRIVATE-CUSTOMER-ID'). self assert: (bytes includesSubstring: hash) ]
 ] ensure: [ server stop ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testPartialPipelineSetupClosesStore [
 | pipeline paths |
 paths := PuntHome duringHome: home do: [ PuntHome forTool: 'sample-tool' ].
 pipeline := PuntTestBrokenPipeline new.
 [ self should: [ pipeline home: paths config: PuntTelemetryConfig new ] raise: Error.
   self assert: pipeline store connection isNil
 ] ensure: [ pipeline abort ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testPrivateDatabaseAndJournal [
 | paths journal |
 paths := PuntHome duringHome: home do: [ PuntHome forTool: 'sample-tool' ].
 store := PuntTelemetryStore new home: paths retentionDays: 90.
 journal := (paths databaseFile pathString , '-journal') asFileReference.
 self assert: (libc stat: paths databaseFile pathString) permissions equals: 8r600.
 self assert: (libc stat: paths toolDirectory pathString) permissions equals: 8r700.
 store connection basicExecute: 'BEGIN IMMEDIATE'.
 [ store connection basicExecute: 'INSERT INTO signals VALUES (''event'',''sample-tool.cli.test'',1,1,1,NULL,NULL,NULL,NULL,NULL,''{}'',NULL)'.
   self assert: (libc stat: journal pathString) permissions equals: 8r600
 ] ensure: [ store connection basicExecute: 'ROLLBACK' ].
 store close. store := nil.
 (PuntPrivateFile open: journal) close.
 File file: journal pathString posixPermissions: 8r666.
 File file: paths databaseFile pathString posixPermissions: 8r666.
 store := PuntTelemetryStore new home: paths retentionDays: 90.
 self assert: (libc stat: paths databaseFile pathString) permissions equals: 8r600.
 journal exists ifTrue: [ self assert: (libc stat: journal pathString) permissions equals: 8r600 ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testQueueCapacityAndHashSnapshot [
 | queue record started |
 record := self observation asRecordAt: (PuntHome duringHome: home do: [ PuntHome forTool: 'sample-tool' ]).
 queue := PuntTelemetryQueue new.
 started := Time millisecondClockValue.
 1024 timesRepeat: [ self assert: (queue push: record) ].
 self deny: (queue push: record).
 self assert: queue size equals: 1024.
 self assert: (Time millisecondsSince: started) < 1000.
 self deny: ((STONJSON toString: queue pop attributes) includesSubstring: 'PRIVATE-CUSTOMER-ID').
 queue close. self deny: (queue push: record)
]

{ #category : 'tests' }
PuntTelemetryTest >> testRejectionsNeverRaise [
 | invalid |
 self start: PuntTelemetryConfig new.
 invalid := { Dictionary new. PuntTestUnknownVersion new. PuntTestUnknownField new.
   PuntTestObservation new. (self observation outcome: 'ok'). (self observation items: -1).
   (self observation enabled: 1). (self observation identifier: 42).
   (self observation identifier: (String new: 65537 withAll: $x)). (self observation outcome: #unknown) }.
 invalid do: [ :each | self deny: (telemetry record: each) ].
 self assert: telemetry dropped equals: invalid size.
 telemetry shutdown. self assert: self rows isEmpty
]

{ #category : 'tests' }
PuntTelemetryTest >> testSaltRaceAndSeparation [
 | paths results done |
 paths := PuntHome duringHome: home do: [ (PuntHome forTool: 'sample-tool') ensureDirectories ].
 PuntTestRacingSalt prepare. results := SharedQueue new. done := Semaphore new.
 2 timesRepeat: [ [ [ results nextPut: (PuntTestRacingSalt new readAt: paths) ] ensure: [ done signal ] ] fork ].
 [ PuntTestRacingSalt ready wait. PuntTestRacingSalt ready wait ] ensure: [ 2 timesRepeat: [ PuntTestRacingSalt go signal ] ].
 done wait. done wait.
 self assert: results next equals: results next.
 self assert: (libc stat: paths saltFile pathString) permissions equals: 8r600.
 self assert: PuntTelemetrySalt allInstVarNames isEmpty.
 self assert: PuntTelemetrySalt classVarNames isEmpty.
 self assert: (PuntTelemetrySalt new hash: 'same' home: paths) equals: (PuntTelemetrySalt new hash: 'same' home: paths).
 self deny: (PuntTelemetrySalt new hash: 'same' home: paths) equals: (PuntTelemetrySalt new hash: 'same' home: (PuntHome duringHome: sandbox do: [ PuntHome forTool: 'other' ]))
]

{ #category : 'tests' }
PuntTelemetryTest >> testSaltRejectsFifoAndEmptyFileWithoutBlocking [
 | paths started |
 paths := PuntHome duringHome: home do: [ (PuntHome forTool: 'sample-tool') ensureDirectories ].
 self assert: (self class makeFifo: paths saltFile pathString mode: 8r600) equals: 0.
 started := Time millisecondClockValue.
 self should: [ PuntTelemetrySalt new readAt: paths ] raise: PuntPermissionError.
 self assert: (Time millisecondsSince: started) < 1000.
 paths saltFile delete.
 (PuntPrivateFile open: paths saltFile) close.
 self should: [ PuntTelemetrySalt new readAt: paths ] raise: PuntPermissionError.
 self assert: (libc stat: paths saltFile pathString) size equals: 0
]

{ #category : 'tests' }
PuntTelemetryTest >> testSourceGateIncludesExtensions [
 | method |
 method := Object compile: 'puntTelemetryGateProbe ^ OTTracerProvider new' classified: '*PuntObserve-Telemetry-Tests'.
 [ self assert: ((PuntLogSourceGate violationsInPackages: #('PuntObserve-Telemetry-Tests') allowing: #()) includes: Object >> method) ]
   ensure: [ Object removeSelector: method ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testSourceGateIncludesNestedProviders [
 | violations |
 violations := PuntLogSourceGate violationsInPackages: #('PuntObserve-Telemetry-Tests') allowing: #().
 self assert: (violations includes: PuntTestForbiddenTelemetry >> #provider).
 self assert: (violations includes: PuntTestFailingSpanExporter name).
 violations := PuntLogSourceGate violationsInPackages: #('PuntObserve-Telemetry-Tests') allowing: #(PuntTestForbiddenTelemetry PuntTelemetryTest PuntTelemetryImagesTest PuntTestFailingSpanExporter PuntTestStalledSpanExporter).
 self assert: violations isEmpty
]

{ #category : 'tests' }
PuntTelemetryTest >> testSourceGateIncludesNonClassOtelGlobals [
 | method |
 method := nil.
 self deny: (Smalltalk globals includesKey: #OTPuntTelemetryGateProbe).
 Smalltalk globals at: #OTPuntTelemetryGateProbe put: Dictionary new.
 [ method := Object compile: 'puntTelemetryGlobalProbe ^ OTPuntTelemetryGateProbe' classified: '*PuntObserve-Telemetry-Tests'.
   self assert: (PuntLogSourceGate forbidden: Object >> method) ]
   ensure: [ method ifNotNil: [ Object removeSelector: method ]. Smalltalk globals removeKey: #OTPuntTelemetryGateProbe ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testSourceGateIncludesOtelExtensionOwners [
 | method |
 method := OTSpanExporter class compile: 'puntTelemetryOwnerProbe ^ true' classified: '*PuntObserve-Telemetry-Tests'.
 [ self assert: ((PuntLogSourceGate violationsInPackages: #('PuntObserve-Telemetry-Tests') allowing: #()) includes: OTSpanExporter class >> method).
   self deny: ((PuntLogSourceGate violationsInPackages: #('PuntObserve-Telemetry-Tests') allowing: #(OTSpanExporter)) includes: OTSpanExporter class >> method) ]
   ensure: [ OTSpanExporter class removeSelector: method ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testSpanLifecycleDoesNotEmitSdkWarnings [
 | previous messages |
 previous := OTDiagnosticLogger current. messages := OrderedCollection new.
 OTDiagnosticLogger current: (OTDiagnosticLogger onMessageDo: [ :severity :message | messages add: message ]).
 [ OTTracerProvider noteSpanProcessor: OTSimpleSpanProcessor new failedDuring: 'shutdown' error: (Error new messageText: 'capture-control').
   self assert: messages size equals: 1. messages removeAll.
   self start: PuntTelemetryConfig new.
   self recordEventually: self observation.
   self waitUntil: [ self rows isNotEmpty ].
   PuntTelemetry shutdown.
   self assert: self rows first first equals: 'span'.
   self assert: telemetry worker isNil.
   self assert: messages isEmpty
 ] ensure: [ PuntTelemetry shutdown. OTDiagnosticLogger current: previous ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testStartupAndIdleRetention [
 | config db |
 config := PuntTelemetryConfig new maintenanceSeconds: 1.
 self start: config.
 self recordEventually: self observation.
 telemetry shutdown.
 db := PuntTelemetryConnection openOn: telemetry home databaseFile pathString.
 [ db basicExecute: 'UPDATE signals SET end_ns=0' ] ensure: [ db forceClose ].
 PuntTelemetry shutdown.
 self start: config.
 self assert: self rows isEmpty.
 db := PuntTelemetryConnection openOn: telemetry home databaseFile pathString.
 [ db basicExecute: 'INSERT INTO signals VALUES (''event'',''sample-tool.cli.test'',1,0,0,NULL,NULL,NULL,NULL,NULL,''{}'',NULL)' ] ensure: [ db forceClose ].
 self waitUntil: [ self rows isEmpty ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testTerminatedTransactionRollsBackWithoutClosingStore [
 | process entered paths |
 paths := PuntHome duringHome: home do: [ PuntHome forTool: 'sample-tool' ].
 store := PuntTelemetryStore new home: paths retentionDays: 90.
 entered := Semaphore new.
 process := [ store transaction: [
   store connection basicExecute: 'INSERT INTO signals VALUES (''event'',''sample-tool.cli.test'',1,0,0,NULL,NULL,NULL,NULL,NULL,''{}'',NULL)'.
   entered signal. Semaphore new wait ] ] fork.
 [ self deny: (entered waitTimeoutMilliseconds: 5000). process terminate.
   self assert: store connection getAutoCommit.
   self assert: self rows isEmpty
 ] ensure: [ process terminate ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testTerminationDuringStoreSetupClosesConnection [
 | process paths |
 paths := PuntHome duringHome: home do: [ PuntHome forTool: 'sample-tool' ].
 store := PuntTestPausedStore new.
 process := [ store home: paths retentionDays: 90 ] fork.
 [ self deny: (store entered waitTimeoutMilliseconds: 5000). process terminate.
   self assert: store connection isNil
 ] ensure: [ process terminate. store close ]
]

{ #category : 'tests' }
PuntTelemetryTest >> testTypedSignalsAndPrivateRows [
 | serialized hash span |
 self start: PuntTelemetryConfig new.
 self recordEventually: (self observation duration: 17).
 { PuntTestEvent. PuntTestCounter. PuntTestHistogram } do: [ :class | self recordEventually: (class new outcome: #ok; identifier: 'PRIVATE-CUSTOMER-ID'; amount: 7) ].
 telemetry shutdown.
 self assert: self rows size equals: 4.
 span := self rows detect: [ :row | row first = 'span' ].
 self assert: (span at: 5) - (span at: 4) equals: 17000000.
 serialized := STONJSON toString: (self rows collect: [ :row | row asArray ]) asArray.
 self deny: (serialized includesSubstring: 'PRIVATE-CUSTOMER-ID').
 hash := PuntTelemetrySalt new hash: 'PRIVATE-CUSTOMER-ID' home: telemetry home.
 self assert: (serialized includesSubstring: hash).
 self deny: (serialized includesSubstring: (PuntTelemetrySalt new readAt: telemetry home) hex).
 self assert: (self rows collect: [ :row | row at: 1 ]) asSet equals: #('span' 'event' 'counter' 'histogram') asSet
]

{ #category : 'tests' }
PuntTelemetryTest >> testUnwritableStoreDoesNotRaiseIntoOperation [
 (home / '.punt-labs') writeStreamDo: [ :stream | stream nextPutAll: 'not a directory' ].
 telemetry := PuntHome duringHome: home do: [ PuntTelemetry startTool: 'sample-tool' config: PuntTelemetryConfig new schemas: self schemas ].
 self recordEventually: (self observation identifier: nil).
 (Delay forMilliseconds: 50) wait.
 self deny: telemetry worker process isTerminated.
 self assert: telemetry worker pipeline isNil.
 self deny: (home / '.punt-labs' / 'sample-tool' / 'telemetry.db') exists
]

{ #category : 'private' }
PuntTelemetryTest >> waitUntil: block [
 | started |
 started := Time millisecondClockValue.
 [ block value or: [ (Time millisecondsSince: started) > 5000 ] ] whileFalse: [ (Delay forMilliseconds: 10) wait ].
 self assert: block value
]
