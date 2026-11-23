"
PHARO-LOG-3, PHARO-TEL-3: machine-scoped private paths, never relative to the image or working directory. Resolve a fresh instance after image startup. Object is justified as a path authority composed with a POSIX adapter.

  (PuntHome forTool: 'example') tool
  >>> 'example'
"
Class {
	#name : 'PuntHome',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'root',
		'libc'
	],
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}

{ #category : 'testing' }
PuntHome class >> duringHome: aFileReference do: aBlock [ ^ PuntHomeRoot value: aFileReference asFileReference during: aBlock
]

{ #category : 'instance creation' }
PuntHome class >> forTool: aString [ ^ self new initializeTool: aString; yourself
]

{ #category : 'private' }
PuntHome class >> isLowercase: aCharacter [ ^ aCharacter between: $a and: $z
]

{ #category : 'validation' }
PuntHome class >> validateTool: aString [
 (aString isString and: [ aString size between: 1 and: 64 ])
   ifFalse: [ PuntPermissionError signal: 'Invalid tool name' ].
 (self isLowercase: aString first) ifFalse: [ PuntPermissionError signal: 'Invalid tool name' ].
 (aString allSatisfy: [ :char | (self isLowercase: char) or: [ ('0123456789-' includes: char) ] ])
   ifFalse: [ PuntPermissionError signal: 'Invalid tool name' ]
]

{ #category : 'accessing' }
PuntHome >> databaseFile [ ^ self toolDirectory / 'telemetry.db'
]

{ #category : 'operating' }
PuntHome >> ensureDirectories [
 { self labsDirectory. self toolDirectory. self logsDirectory } do: [ :path | self secureDirectory: path ].
 ^ self
]

{ #category : 'initialization' }
PuntHome >> initializeTool: aString [
 self class validateTool: aString.
 tool := aString.
 root := PuntHomeRoot value ifNil: [ FileLocator home asFileReference ].
 libc := PuntLibC new
]

{ #category : 'accessing' }
PuntHome >> labsDirectory [ ^ root / '.punt-labs'
]

{ #category : 'accessing' }
PuntHome >> libc: anAdapter [ libc := anAdapter
]

{ #category : 'accessing' }
PuntHome >> lockFile [ ^ self logsDirectory / (tool , '.log.rotate.lock')
]

{ #category : 'accessing' }
PuntHome >> logFile [ ^ self logsDirectory / (tool , '.log')
]

{ #category : 'accessing' }
PuntHome >> logsDirectory [ ^ self toolDirectory / 'logs'
]

{ #category : 'accessing' }
PuntHome >> root [ ^ root
]

{ #category : 'accessing' }
PuntHome >> saltFile [ ^ self labsDirectory / 'telemetry.salt'
]

{ #category : 'private' }
PuntHome >> secureDirectory: aFileReference [
 | descriptor |
 (libc mkdir: aFileReference pathString mode: 8r700) = 0 ifFalse: [
   libc errno = 17 ifFalse: [ PuntPermissionError signal: 'Cannot create private directory' ] ].
 descriptor := libc open: aFileReference pathString flags: libc readDirectoryFlags mode: 0.
 descriptor < 0 ifTrue: [ PuntPermissionError signal: 'Cannot open private directory' ].
 [ libc secure: descriptor directory: true ] ensure: [ libc close: descriptor ]
]

{ #category : 'accessing' }
PuntHome >> tool [ ^ tool
]

{ #category : 'accessing' }
PuntHome >> toolDirectory [ ^ self labsDirectory / tool
]
