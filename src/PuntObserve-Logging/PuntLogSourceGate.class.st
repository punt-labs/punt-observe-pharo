"
PHARO-LOG-1, PHARO-TEL-1: Reusable consumer gate for compiled global references, nested blocks, forbidden inheritance and extension owners, with an explicit entry-point class allowlist. Dynamic global lookups are outside this static gate. Object is the service boundary.

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
       (literal key beginsWith: 'OT') or: [
         (literal value isBehavior and: [ literal value = SignalLogger or: [ literal value inheritsFrom: SignalLogger ] ]) or: [
           literal key = #ZnLogEvent and: [ literals includes: #announcer ] ] ] ] ] ]
]

{ #category : 'private' }
PuntLogSourceGate class >> forbiddenClass: aClass [
 ^ aClass withAllSuperclasses anySatisfy: [ :ancestor | ancestor = SignalLogger or: [ ancestor name beginsWith: 'OT' ] ]
]

{ #category : 'private' }
PuntLogSourceGate class >> inspect: aClass into: violations [
 (self forbiddenClass: aClass) ifTrue: [ violations add: aClass name ].
 violations addAll: ((aClass methods , aClass class methods) select: [ :method | self forbidden: method ])
]

{ #category : 'testing' }
PuntLogSourceGate class >> violationsInPackages: packageNames allowing: allowedClasses [
 | violations |
 violations := OrderedCollection new.
 packageNames do: [ :packageName | | package |
   package := PackageOrganizer default packageNamed: packageName.
   package definedClasses do: [ :class | (allowedClasses includes: class name) ifFalse: [ self inspect: class into: violations ] ].
   violations addAll: (package extensionMethods select: [ :each |
     | owner |
     owner := each methodClass instanceSide.
     (allowedClasses includes: owner name) not and: [ (self forbiddenClass: owner) or: [ self forbidden: each ] ] ]) ].
 ^ violations
]
