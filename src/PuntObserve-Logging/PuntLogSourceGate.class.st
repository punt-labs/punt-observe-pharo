"
PHARO-LOG-1: Reusable compiled-reference scan of consumer packages, including nested blocks, with an explicit entry-point class allowlist. Dynamic global lookups are outside this static gate. Object is the service or value boundary.

  PuntLogSourceGate new class name
  >>> #PuntLogSourceGate
"
Class {
	#name : 'PuntLogSourceGate',
	#superclass : 'Object',
	#category : 'PuntObserve-Logging',
	#package : 'PuntObserve-Logging'
}

{ #category : 'private' }
PuntLogSourceGate class >> forbidden: aMethod [
 | literals |
 literals := aMethod literalsEvenTheOnesInTheInnerBlocks.
 ^ literals anySatisfy: [ :literal |
   literal isVariableBinding and: [
     (#(Transcript Stdio) includes: literal key) or: [
       (literal value isBehavior and: [ literal value = SignalLogger or: [ literal value inheritsFrom: SignalLogger ] ]) or: [
         literal key = #ZnLogEvent and: [ literals includes: #announcer ] ] ] ] ]
]

{ #category : 'private' }
PuntLogSourceGate class >> inspect: aClass into: violations [
 (aClass inheritsFrom: SignalLogger) ifTrue: [ violations add: aClass name ].
 violations addAll: ((aClass methods , aClass class methods) select: [ :method | self forbidden: method ])
]

{ #category : 'testing' }
PuntLogSourceGate class >> violationsInPackages: packageNames allowing: allowedClasses [
 | violations |
 violations := OrderedCollection new.
 (Smalltalk globals allClasses select: [ :class | packageNames includes: class package name ]) do: [ :class |
   (allowedClasses includes: class name) ifFalse: [ self inspect: class into: violations ] ].
 ^ violations
]
