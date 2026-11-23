"
PHARO-LOG-4, PHARO-LOG-5: Controlled short-write and I/O failure without writing partial test records.

  (PuntTestWriteFailureLibC new kind: #shortWrite) class name
  >>> #PuntTestWriteFailureLibC
"
Class {
	#name : 'PuntTestWriteFailureLibC',
	#superclass : 'PuntLibC',
	#instVars : [
		'kind'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntTestWriteFailureLibC >> kind: aSymbol [ kind := aSymbol
]

{ #category : 'ffi' }
PuntTestWriteFailureLibC >> write: fd bytes: bytes count: count [
 kind = #negativeResult ifTrue: [ ^ -1 ].
 kind = #shortWrite ifTrue: [ ^ count - 1 ].
 kind = #partialOnce ifTrue: [ kind := #normal. ^ super write: fd bytes: bytes count: count - 1 ].
 kind = #normal ifTrue: [ ^ super write: fd bytes: bytes count: count ].
 PuntPermissionError signal: 'Synthetic private write failure'
]
