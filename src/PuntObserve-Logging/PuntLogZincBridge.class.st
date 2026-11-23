"
PHARO-LOG-2, PHARO-LOG-6: Caller-owned, idempotent Zinc subscription rendering only event class names at DEBUG. The caller must stop the bridge. Object is the service or value boundary.

  PuntLogZincBridge new class name
  >>> #PuntLogZincBridge
"
Class {
	#name : 'PuntLogZincBridge',
	#superclass : 'Object',
	#instVars : [
		'running'
	],
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'operating' }
PuntLogZincBridge >> receive: anEvent [
 (PuntLogDebugSignal new component: 'zinc'; message: anEvent class name) emit
]

{ #category : 'operating' }
PuntLogZincBridge >> start [
 running ifNotNil: [ running ifTrue: [ ^ self ] ].
 ZnLogEvent announcer when: ZnLogEvent send: #receive: to: self.
 running := true
]

{ #category : 'operating' }
PuntLogZincBridge >> stop [ ZnLogEvent announcer unsubscribe: self. running := false
]
