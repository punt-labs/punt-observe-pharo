"
PHARO-LOG-3, PHARO-LOG-4: Acceptance fixture for PHARO-LOG-3, PHARO-LOG-4; deterministic isolation of logging behavior.

  PuntLogSinkTest new class name
  >>> #PuntLogSinkTest
"
Class {
	#name : 'PuntLogSinkTest',
	#superclass : 'PuntHomeTest',
	#instVars : [
		'sink'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'private' }
PuntLogSinkTest >> start [ sink := PuntHome duringHome: home do: [ PuntLogSink forTool: 'sample-tool' ]. sink noticesEnabled: false
]

{ #category : 'running' }
PuntLogSinkTest >> tearDown [ sink ifNotNil: [ sink close ]. super tearDown
]

{ #category : 'tests' }
PuntLogSinkTest >> testCloseDrainsActiveCriticalSection [
 | acquired release holder closer |
 sink := PuntHome duringHome: home do: [ PuntTestLockedSink forTool: 'sample-tool' ].
 acquired := Semaphore new. release := Semaphore new.
 holder := [ sink hold: [ acquired signal. release wait ] ] fork.
 acquired wait.
 closer := [ sink close ] fork.
 [ (Delay forMilliseconds: 20) wait. self deny: closer isTerminated ] ensure: [ release signal ].
 [ holder isTerminated and: [ closer isTerminated ] ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
 self deny: (sink append: 'closed' utf8Encoded).
 sink close
]

{ #category : 'tests' }
PuntLogSinkTest >> testExactPathsModesAndExistingBackups [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   { paths logFile. paths lockFile. paths logsDirectory / 'sample-tool.log.1' } do: [ :path |
     | file |
     file := PuntPrivateFile open: path. file close.
     File file: path pathString posixPermissions: 8r666 ] ].
 self start.
 self assert: sink home logFile equals: home / '.punt-labs' / 'sample-tool' / 'logs' / 'sample-tool.log'.
 { sink home logFile. sink home lockFile. sink backup: 1 } do: [ :path |
   self assert: (libc stat: path pathString) permissions equals: 8r600 ]
]

{ #category : 'tests' }
PuntLogSinkTest >> testHeldFlockTimeoutThenRecovery [
 | held started |
 self start.
 held := PuntPrivateFile open: sink home lockFile.
 [ self assert: (libc tryLock: held descriptor) equals: 0.
   started := Time millisecondClockValue.
   self deny: (sink append: 'skipped
' utf8Encoded).
   self assert: (Time millisecondsSince: started) >= 1900.
   self assert: (Time millisecondsSince: started) < 3000.
   self assert: sink noticeCount equals: 1.
   sink timeoutNotice.
   self assert: sink noticeCount equals: 1
 ] ensure: [ libc unlock: held descriptor. held close ].
 self assert: (sink append: 'later
' utf8Encoded).
 self assert: sink home logFile contents equals: 'later
'
]

{ #category : 'tests' }
PuntLogSinkTest >> testLocalMutexHasSameBoundedBudget [
 | acquired release holder started |
 sink := PuntHome duringHome: home do: [ PuntTestLockedSink forTool: 'sample-tool' ].
 sink noticesEnabled: false.
 acquired := Semaphore new. release := Semaphore new.
 holder := [ sink hold: [ acquired signal. release wait ] ] fork.
 acquired wait.
 [ started := Time millisecondClockValue.
   self deny: (sink append: 'blocked' utf8Encoded).
   self assert: (Time millisecondsSince: started) >= 1900.
   self assert: (Time millisecondsSince: started) < 3000
 ] ensure: [ release signal ].
 [ holder isTerminated ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
 self assert: (sink append: 'recovered' utf8Encoded)
]
