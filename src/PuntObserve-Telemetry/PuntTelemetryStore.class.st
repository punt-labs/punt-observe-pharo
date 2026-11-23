"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Worker-owned private SQLite connection, transactional rows, bounded busy waits and incremental expiry reclamation. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryStore new class name
  >>> #PuntTelemetryStore
"
Class {
	#name : 'PuntTelemetryStore',
	#superclass : 'Object',
	#instVars : [
		'connection',
		'home',
		'days'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'operating' }
PuntTelemetryStore >> close [
 connection ifNotNil: [ connection forceClose. connection := nil ]
]

{ #category : 'accessing' }
PuntTelemetryStore >> connection [ ^ connection
]

{ #category : 'accessing' }
PuntTelemetryStore >> home [ ^ home
]

{ #category : 'initialization' }
PuntTelemetryStore >> home: aHome retentionDays: retention [
 home := aHome. days := retention.
 home ensureDirectories. self secureFiles.
 connection := PuntTelemetryConnection on: home databaseFile pathString.
 [ connection open. self prepare. self prune ] ifCurtailed: [ self close ].
 ^ self
]

{ #category : 'operating' }
PuntTelemetryStore >> insert: values [
 connection execute: 'INSERT INTO signals VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)' with: values doing: [ :cursor | ]
]

{ #category : 'converting' }
PuntTelemetryStore >> metricValues: metric point: point [
 | histogram aggregation version |
 version := point attributes at: 'punt.schema.version' ifAbsent: [ ^ nil ].
 (version isInteger and: [ version > 0 ]) ifFalse: [ ^ nil ].
 histogram := metric kind = #histogram.
 aggregation := histogram ifTrue: [ STONJSON toString: { 'bounds' -> point explicitBounds. 'buckets' -> point bucketCounts } asDictionary ] ifFalse: [ 'delta' ].
 ^ { histogram ifTrue: [ 'histogram' ] ifFalse: [ 'counter' ]. metric name. version.
     self nanoseconds: point startTimestamp. self nanoseconds: point timestamp. nil. nil. metric unit.
     histogram ifTrue: [ point sum ] ifFalse: [ point value ]. histogram ifTrue: [ point count ] ifFalse: [ nil ].
     STONJSON toString: point attributes. aggregation }
]

{ #category : 'converting' }
PuntTelemetryStore >> nanoseconds: timestamp [ ^ (timestamp asUnixTime * 1000000000) + timestamp nanoSecond
]

{ #category : 'private' }
PuntTelemetryStore >> prepare [
 connection basicExecute: 'PRAGMA busy_timeout=200'.
 connection basicExecute: 'PRAGMA journal_mode=DELETE'.
 connection basicExecute: 'PRAGMA auto_vacuum=INCREMENTAL'.
 connection basicExecute: 'CREATE TABLE IF NOT EXISTS signals (signal TEXT NOT NULL, name TEXT NOT NULL, schema_version INTEGER NOT NULL, start_ns INTEGER NOT NULL, end_ns INTEGER NOT NULL, trace_id TEXT, span_id TEXT, unit TEXT, value INTEGER, count INTEGER, attributes TEXT NOT NULL, aggregation TEXT)'.
 connection basicExecute: 'CREATE INDEX IF NOT EXISTS signals_expiry ON signals(end_ns)'.
 connection basicExecute: 'PRAGMA user_version=1'
]

{ #category : 'operating' }
PuntTelemetryStore >> prune [
 | cutoff |
 cutoff := (DateAndTime now asUnixTime - (days * 86400)) * 1000000000.
 connection execute: 'DELETE FROM signals WHERE end_ns < ?' with: { cutoff } doing: [ :cursor | ].
 connection basicExecute: 'PRAGMA incremental_vacuum(256)'
]

{ #category : 'private' }
PuntTelemetryStore >> secureFiles [
 | file libc |
 file := PuntPrivateFile open: home databaseFile. file close.
 libc := PuntLibC new.
 #('-journal' '-wal' '-shm') do: [ :suffix |
   | path |
   path := (String streamContents: [ :stream | stream nextPutAll: home databaseFile pathString; nextPutAll: suffix ]) asFileReference.
   (libc exists: path) ifTrue: [ file := PuntPrivateFile open: path. file close ] ]
]

{ #category : 'converting' }
PuntTelemetryStore >> spanValues: span [
 | attributes kind event start end |
 attributes := span attributes copy.
 kind := attributes removeKey: 'punt.signal.kind' ifAbsent: [ 'span' ].
 start := span startTime. end := span endTime.
 kind = 'event' ifTrue: [ event := span events first. attributes := event attributes copy. start := event timestamp. end := start ].
 ^ { kind. span name. attributes at: 'punt.schema.version'. self nanoseconds: start. self nanoseconds: end.
     span traceId. span spanId. nil. nil. nil. STONJSON toString: attributes. nil }
]

{ #category : 'operating' }
PuntTelemetryStore >> transaction: aBlock [
 connection basicExecute: 'BEGIN IMMEDIATE'.
 [ aBlock value. connection basicExecute: 'COMMIT' ]
   ifCurtailed: [ connection basicExecute: 'ROLLBACK' ]
]
