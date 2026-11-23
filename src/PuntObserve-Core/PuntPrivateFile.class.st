"
PHARO-LOG-3, PHARO-LOG-4, PHARO-TEL-3: an owned regular append descriptor, created exclusively at 0600 or validated and tightened before use. Caller owns close. Object is justified as a descriptor lifecycle boundary.

  PuntPrivateFile new isOpen
  >>> false
"
Class {
	#name : 'PuntPrivateFile',
	#superclass : 'Object',
	#instVars : [
		'descriptor',
		'libc',
		'path'
	],
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}

{ #category : 'instance creation' }
PuntPrivateFile class >> open: aFileReference [ ^ self open: aFileReference using: PuntLibC new
]

{ #category : 'instance creation' }
PuntPrivateFile class >> open: aFileReference using: anAdapter [ ^ self new open: aFileReference using: anAdapter; yourself
]

{ #category : 'operating' }
PuntPrivateFile >> append: aByteArray [
 | written |
 self isOpen ifFalse: [ PuntPermissionError signal: 'Private file is closed' ].
 written := libc write: descriptor bytes: aByteArray count: aByteArray size.
 written = aByteArray size ifFalse: [ PuntPermissionError signal: 'Private append incomplete' ].
 ^ written
]

{ #category : 'operating' }
PuntPrivateFile >> close [
 | oldDescriptor |
 self isOpen ifFalse: [ ^ self ].
 oldDescriptor := descriptor.
 descriptor := nil.
 (libc close: oldDescriptor) = 0 ifFalse: [ PuntPermissionError signal: 'Private close failed' ]
]

{ #category : 'accessing' }
PuntPrivateFile >> descriptor [ ^ descriptor
]

{ #category : 'accessing' }
PuntPrivateFile >> inode [ ^ self metadata inode
]

{ #category : 'testing' }
PuntPrivateFile >> isOpen [ ^ descriptor notNil and: [ descriptor >= 0 ]
]

{ #category : 'accessing' }
PuntPrivateFile >> metadata [ ^ libc fstat: descriptor
]

{ #category : 'initialization' }
PuntPrivateFile >> open: aFileReference using: anAdapter [
 path := aFileReference asFileReference.
 libc := anAdapter.
 descriptor := libc open: path pathString flags: libc createFlags mode: 8r600.
 descriptor < 0 ifTrue: [
   libc errno = 17 ifFalse: [ PuntPermissionError signal: 'Cannot create private file' ].
   descriptor := libc open: path pathString flags: libc appendFlags mode: 0 ].
 descriptor < 0 ifTrue: [ PuntPermissionError signal: 'Cannot open private file' ].
 [ libc secure: descriptor directory: false ]
   on: Error do: [ :error | self close. error pass ]
]

{ #category : 'accessing' }
PuntPrivateFile >> path [ ^ path
]

{ #category : 'accessing' }
PuntPrivateFile >> size [ ^ self metadata size
]
