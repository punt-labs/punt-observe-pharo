"
PHARO-LOG-3, PHARO-LOG-4, PHARO-TEL-3: private POSIX file operations. Linux x86_64 and macOS 64-bit stat layouts; only nonblocking lock acquisition is exposed. stat: uses lstat so links remain visible.

  PuntLibC new createFlag > 0
  >>> true
"
Class {
	#name : 'PuntLibC',
	#superclass : 'Object',
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}

{ #category : 'constants' }
PuntLibC >> appendFlag [ ^ Smalltalk os isMacOS ifTrue: [ 8 ] ifFalse: [ 16r400 ]
]

{ #category : 'constants' }
PuntLibC >> appendFlags [ ^ 1 bitOr: (self appendFlag bitOr: (self noFollowFlag bitOr: self nonBlockingFlag))
]

{ #category : 'ffi' }
PuntLibC >> basicFlock: fd operation: operation [
 ^ self ffiCall: #(int flock(int fd, int operation)) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> basicFstat: fd into: buffer [
 ^ self ffiCall: { #int. self statSymbol: 'fstat'. #(int fd , void* buffer) } library: LibC
]

{ #category : 'ffi' }
PuntLibC >> basicLstat: path into: buffer [
 ^ self ffiCall: { #int. self statSymbol: 'lstat'. #(String path , void* buffer) } library: LibC
]

{ #category : 'ffi' }
PuntLibC >> chdir: path [
 ^ self ffiCall: #(int chdir(String path)) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> close: fd [
 ^ self ffiCall: #(int close(int fd)) library: LibC
]

{ #category : 'constants' }
PuntLibC >> createFlag [ ^ Smalltalk os isMacOS ifTrue: [ 16r200 ] ifFalse: [ 16r40 ]
]

{ #category : 'constants' }
PuntLibC >> createFlags [ ^ self appendFlags bitOr: (self createFlag bitOr: self exclusiveFlag)
]

{ #category : 'constants' }
PuntLibC >> directoryFlag [ ^ Smalltalk os isMacOS ifTrue: [ 16r100000 ] ifFalse: [ 16r10000 ]
]

{ #category : 'accessing' }
PuntLibC >> errno [ ^ (Smalltalk os isMacOS ifTrue: [ self macErrnoAddress ] ifFalse: [ self linuxErrnoAddress ]) signedLongAt: 1
]

{ #category : 'constants' }
PuntLibC >> exclusiveFlag [ ^ Smalltalk os isMacOS ifTrue: [ 16r800 ] ifFalse: [ 16r80 ]
]

{ #category : 'testing' }
PuntLibC >> exists: path [
 ^ [ self stat: path pathString. true ] on: PuntPermissionError do: [ :error |
   | parent |
   parent := self open: path parent pathString flags: self readDirectoryFlags mode: 0.
   parent < 0 ifTrue: [ error pass ].
   [ self secure: parent directory: true ] ensure: [ self close: parent ].
   (path exists or: [ path isSymlink ]) ifTrue: [ error pass ].
   false ]
]

{ #category : 'ffi' }
PuntLibC >> fchmod: fd mode: mode [
 ^ self ffiCall: #(int fchmod(int fd, int mode)) library: LibC
]

{ #category : 'accessing' }
PuntLibC >> fstat: aDescriptor [ ^ self metadataUsing: [ :buffer | self basicFstat: aDescriptor into: buffer ]
]

{ #category : 'ffi' }
PuntLibC >> getuid [
 ^ self ffiCall: #(uint getuid()) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> link: oldPath to: newPath [
 ^ self ffiCall: #(int link(String oldPath, String newPath)) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> linuxErrnoAddress [
 ^ self ffiCall: #(void* __errno_location()) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> macErrnoAddress [
 ^ self ffiCall: #(void* __error()) library: LibC
]

{ #category : 'private' }
PuntLibC >> macMetadataFrom: buffer [
 ^ PuntFileStat new
   inode: (buffer unsignedLongLongAt: 9);
   mode: (buffer unsignedShortAt: 5);
   uid: (buffer unsignedLongAt: 17);
   size: (buffer signedLongLongAt: 97);
   yourself
]

{ #category : 'private' }
PuntLibC >> metadataFrom: buffer [
 Smalltalk os isMacOS ifTrue: [ ^ self macMetadataFrom: buffer ].
 ^ PuntFileStat new
   inode: (buffer unsignedLongLongAt: 9);
   mode: (buffer unsignedLongAt: 25);
   uid: (buffer unsignedLongAt: 29);
   size: (buffer signedLongLongAt: 49);
   yourself
]

{ #category : 'private' }
PuntLibC >> metadataUsing: aBlock [
 | buffer |
 buffer := ExternalAddress allocate: 256.
 ^ [ (aBlock value: buffer) = 0 ifFalse: [ PuntPermissionError signal: 'Cannot inspect private path' ].
     self metadataFrom: buffer ] ensure: [ buffer free ]
]

{ #category : 'ffi' }
PuntLibC >> mkdir: path mode: mode [
 ^ self ffiCall: #(int mkdir(String path, int mode)) library: LibC
]

{ #category : 'constants' }
PuntLibC >> noFollowFlag [ ^ Smalltalk os isMacOS ifTrue: [ 16r100 ] ifFalse: [ 16r20000 ]
]

{ #category : 'constants' }
PuntLibC >> nonBlockingFlag [ ^ Smalltalk os isMacOS ifTrue: [ 4 ] ifFalse: [ 16r800 ]
]

{ #category : 'ffi' }
PuntLibC >> open: path flags: flags mode: mode [
 ^ self ffiCall: #(int open(String path, int flags, int mode)) library: LibC
]

{ #category : 'ffi' }
PuntLibC >> read: fd bytes: bytes count: count [ ^ self ffiCall: #(long read(int fd, ByteArray bytes, ulong count)) library: LibC
]

{ #category : 'constants' }
PuntLibC >> readDirectoryFlags [ ^ self noFollowFlag bitOr: self directoryFlag
]

{ #category : 'ffi' }
PuntLibC >> rename: oldPath to: newPath [
 ^ self ffiCall: #(int rename(String oldPath, String newPath)) library: LibC
]

{ #category : 'validation' }
PuntLibC >> secure: aDescriptor directory: aBoolean [
 | metadata expected |
 metadata := self fstat: aDescriptor.
 metadata uid = self getuid ifFalse: [ PuntPermissionError signal: 'Private path has another owner' ].
 (aBoolean ifTrue: [ metadata isDirectory ] ifFalse: [ metadata isRegular ])
   ifFalse: [ PuntPermissionError signal: 'Private path has wrong type' ].
 expected := aBoolean ifTrue: [ 8r700 ] ifFalse: [ 8r600 ].
 (self fchmod: aDescriptor mode: expected) = 0
   ifFalse: [ PuntPermissionError signal: 'Cannot tighten private path' ].
 (self fstat: aDescriptor) permissions = expected
   ifFalse: [ PuntPermissionError signal: 'Private mode verification failed' ]
]

{ #category : 'accessing' }
PuntLibC >> stat: aPath [ ^ self metadataUsing: [ :buffer | self basicLstat: aPath into: buffer ]
]

{ #category : 'private' }
PuntLibC >> statSymbol: name [
 ^ self statSymbol: name macOS: Smalltalk os isMacOS architecture: Smalltalk vm architectureName
]

{ #category : 'private' }
PuntLibC >> statSymbol: name macOS: mac architecture: architecture [
 ^ (mac and: [ #('x86_64' 'x64') includes: architecture asString ])
   ifTrue: [ name , '$INODE64' ] ifFalse: [ name ]
]

{ #category : 'ffi' }
PuntLibC >> symlink: target to: path [
 ^ self ffiCall: #(int symlink(String target, String path)) library: LibC
]

{ #category : 'locking' }
PuntLibC >> tryLock: aDescriptor [ ^ self basicFlock: aDescriptor operation: 6
]

{ #category : 'ffi' }
PuntLibC >> unlink: path [
 ^ self ffiCall: #(int unlink(String path)) library: LibC
]

{ #category : 'locking' }
PuntLibC >> unlock: aDescriptor [ ^ self basicFlock: aDescriptor operation: 8
]

{ #category : 'ffi' }
PuntLibC >> write: fd bytes: bytes count: count [
 ^ self ffiCall: #(long write(int fd, ByteArray bytes, ulong count)) library: LibC
]
