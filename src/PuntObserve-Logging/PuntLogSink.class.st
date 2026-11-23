"
PHARO-LOG-3, PHARO-LOG-4, PHARO-LOG-5: Private append-and-rotate boundary. One Mutex and stable nonblocking flock cover opening, size checks, five-backup rotation and each complete write. Acquisition shares a two-second budget. Object is the service or value boundary.

  PuntLogSink new class name
  >>> #PuntLogSink
"
Class {
	#name : 'PuntLogSink',
	#superclass : 'Object',
	#instVars : [
		'home',
		'mutex',
		'libc',
		'closed',
		'noticeAt',
		'noticesEnabled',
		'noticeCount'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'instance creation' }
PuntLogSink class >> forTool: aString [ ^ self new tool: aString
]

{ #category : 'operating' }
PuntLogSink >> append: bytes [
 ^ [
   (closed or: [ bytes isNil or: [ bytes size > 65536 ] ]) ifTrue: [ false ] ifFalse: [
     self locked: [ self appendLocked: bytes ] ]
 ] on: Error do: [ :error | false ]
]

{ #category : 'private' }
PuntLogSink >> appendLocked: bytes [
 | file |
 file := PuntPrivateFile open: home logFile.
 [
   file size + bytes size > self maximumBytes ifTrue: [
     file close.
     self rotate.
     file := PuntPrivateFile open: home logFile ].
   file append: bytes
 ] ensure: [ file close ]
]

{ #category : 'accessing' }
PuntLogSink >> backup: index [ ^ home logsDirectory / (home logFile basename , '.' , index asString)
]

{ #category : 'operating' }
PuntLogSink >> close [ closed := true. mutex critical: [ ^ self ]
]

{ #category : 'private' }
PuntLogSink >> exists: path [
 ^ [ libc stat: path pathString. true ] on: PuntPermissionError do: [ :error |
   libc errno = 2 ifTrue: [ false ] ifFalse: [ error pass ] ]
]

{ #category : 'private' }
PuntLogSink >> flockFrom: started do: aBlock [
 | lock |
 lock := PuntPrivateFile open: home lockFile.
 ^ [
   [ (libc tryLock: lock descriptor) = 0 ] whileFalse: [
     (Time millisecondsSince: started) >= 2000 ifTrue: [ self timeoutNotice. ^ false ].
     (Delay forMilliseconds: 10) wait ].
   [ aBlock value. true ] ensure: [ libc unlock: lock descriptor ]
 ] ensure: [ lock close ]
]

{ #category : 'accessing' }
PuntLogSink >> home [ ^ home
]

{ #category : 'initialization' }
PuntLogSink >> initialize [
 super initialize. mutex := Mutex new. libc := PuntLibC new. closed := false.
 noticesEnabled := true. noticeCount := 0
]

{ #category : 'accessing' }
PuntLogSink >> libc: anAdapter [ libc := anAdapter
]

{ #category : 'private' }
PuntLogSink >> locked: aBlock [
 | started result |
 started := Time millisecondClockValue.
 [
   result := mutex tryEnterCritical: [ closed ifTrue: [ false ] ifFalse: [ self flockFrom: started do: aBlock ] ] ifLocked: [ #busy ].
   result == #busy
 ] whileTrue: [
   (Time millisecondsSince: started) >= 2000 ifTrue: [ self timeoutNotice. ^ false ].
   (Delay forMilliseconds: 10) wait ].
 ^ result
]

{ #category : 'accessing' }
PuntLogSink >> maximumBytes [ ^ 5242880
]

{ #category : 'private' }
PuntLogSink >> move: source to: destination [
 (self exists: source) ifTrue: [
   (libc rename: source pathString to: destination pathString) = 0 ifFalse: [ PuntPermissionError signal: 'Cannot rotate diagnostic file' ] ]
]

{ #category : 'accessing' }
PuntLogSink >> noticeCount [ ^ noticeCount
]

{ #category : 'accessing' }
PuntLogSink >> noticesEnabled [ ^ noticesEnabled
]

{ #category : 'accessing' }
PuntLogSink >> noticesEnabled: aBoolean [ noticesEnabled := aBoolean
]

{ #category : 'private' }
PuntLogSink >> prepareActive [
 | file oversized |
 file := PuntPrivateFile open: home logFile.
 oversized := [ file size > self maximumBytes ] ensure: [ file close ].
 oversized ifFalse: [ ^ self ].
 self remove: home logFile. file := PuntPrivateFile open: home logFile. file close
]

{ #category : 'private' }
PuntLogSink >> remove: path [
 (libc unlink: path pathString) = 0 ifFalse: [ PuntPermissionError signal: 'Cannot remove diagnostic file' ]
]

{ #category : 'private' }
PuntLogSink >> rotate [
 self secureBackups.
 (self exists: (self backup: 5)) ifTrue: [ self remove: (self backup: 5) ].
 5 to: 2 by: -1 do: [ :index | self move: (self backup: index - 1) to: (self backup: index) ].
 self move: home logFile to: (self backup: 1)
]

{ #category : 'private' }
PuntLogSink >> secureBackups [
 1 to: 5 do: [ :index |
   | path file |
   path := self backup: index.
   (self exists: path) ifTrue: [
     file := PuntPrivateFile open: path.
     [ file size > self maximumBytes ifTrue: [ self remove: path ] ] ensure: [ file close ] ] ]
]

{ #category : 'private' }
PuntLogSink >> timeoutNotice [
 (noticeAt notNil and: [ (Time millisecondsSince: noticeAt) < 60000 ]) ifTrue: [ ^ self ].
 noticeAt := Time millisecondClockValue. noticeCount := noticeCount + 1.
 noticesEnabled ifTrue: [ Stdio stderr nextPutAll: 'PuntObserve: diagnostic record skipped (lock timeout).'; lf; flush ]
]

{ #category : 'initialization' }
PuntLogSink >> tool: aString [
 home := (PuntHome forTool: aString) ensureDirectories.
 (self locked: [ self secureBackups. self prepareActive ]) ifFalse: [ PuntPermissionError signal: 'Diagnostic setup lock unavailable' ].
 ^ self
]
