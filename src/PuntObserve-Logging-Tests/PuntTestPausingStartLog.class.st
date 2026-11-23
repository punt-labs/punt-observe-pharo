"
PHARO-LOG-2: Pauses one logger start while the lifecycle mutex is held, allowing a deterministic overlapping session transition.

  PuntTestPausingStartLog new class name
  >>> #PuntTestPausingStartLog
"
Class {
	#name : 'PuntTestPausingStartLog',
	#superclass : 'PuntLog',
	#classVars : [
		'Barrier'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'accessing' }
PuntTestPausingStartLog class >> barrier: semaphores [
 Barrier := semaphores
]

{ #category : 'private' }
PuntTestPausingStartLog class >> pauseStart [
 | barrier |
 barrier := Barrier. Barrier := nil.
 barrier ifNotNil: [ barrier first signal. barrier second wait ]
]

{ #category : 'private' }
PuntTestPausingStartLog class >> registerSession [
 PuntLog registerSession
]

{ #category : 'registration' }
PuntTestPausingStartLog >> start [
 self class pauseStart. super start
]
