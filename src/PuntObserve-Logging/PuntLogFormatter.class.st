"
PHARO-LOG-6: Local-time, second-precision rendering of a typed diagnostic before complete-record redaction. Object is the service or value boundary.

  PuntLogFormatter new class name
  >>> #PuntLogFormatter
"
Class {
	#name : 'PuntLogFormatter',
	#superclass : 'Object',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'formatting' }
PuntLogFormatter >> format: aSignal [
 ^ String streamContents: [ :stream |
   self timestamp: aSignal timestamp on: stream.
   stream nextPutAll: ' ['; nextPutAll: (PuntLogLevel label: aSignal level); nextPutAll: '] ';
     nextPutAll: (PuntEscaper escape: aSignal component); nextPutAll: ': '.
   aSignal printOneLineContentsOn: stream ]
]

{ #category : 'private' }
PuntLogFormatter >> timestamp: aTimestamp on: stream [
 | local |
 local := aTimestamp asLocal.
 stream nextPutAll: (local year asString padLeftTo: 4 with: $0); nextPut: $-.
 self twoDigits: local monthIndex on: stream. stream nextPut: $-.
 self twoDigits: local dayOfMonth on: stream. stream space.
 self twoDigits: local hour on: stream. stream nextPut: $:.
 self twoDigits: local minute on: stream. stream nextPut: $:.
 self twoDigits: local second asInteger on: stream
]

{ #category : 'private' }
PuntLogFormatter >> twoDigits: number on: stream [ stream nextPutAll: (number asString padLeftTo: 2 with: $0)
]
