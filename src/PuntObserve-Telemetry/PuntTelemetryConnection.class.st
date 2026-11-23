"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Private SQLite connection releases finalizer registration before deterministic close, preventing a later native double close. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryConnection new class name
  >>> #PuntTelemetryConnection
"
Class {
	#name : 'PuntTelemetryConnection',
	#superclass : 'SQLite3Connection',
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'public API - open/close' }
PuntTelemetryConnection >> forceClose [
 | handle |
 handle := dbHandle.
 handle ifNil: [ ^ self ].
 handle manualRelease.
 [ super forceClose ] ensure: [ handle beNull ]
]
