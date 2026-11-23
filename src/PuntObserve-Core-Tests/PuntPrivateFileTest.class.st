"
PHARO-LOG-3, PHARO-LOG-4: descriptor identity, append bytes, lock and backup privacy, wrong types and permission failures.

  self new
  >>> a PuntPrivateFileTest
"
Class {
	#name : 'PuntPrivateFileTest',
	#superclass : 'PuntHomeTest',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'tests' }
PuntPrivateFileTest >> testAppendAndIdentity [
 self withHomeDo: [ :paths |
   | file inode |
   paths ensureDirectories.
   file := PuntPrivateFile open: paths logFile.
   [ inode := file inode.
     self assert: file size equals: 0.
     file append: 'one' utf8Encoded; append: 'two' utf8Encoded.
     self assert: file size equals: 6.
     self assert: file inode equals: inode ] ensure: [ file close ].
   self assert: paths logFile contents equals: 'onetwo'.
   self deny: file isOpen.
   self should: [ file append: #[] ] raise: PuntPermissionError.
   file close ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testDeniedFileTightening [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   self should: [ PuntPrivateFile open: paths logFile using: PuntFailingLibC new ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testDirectoryInPlaceOfFileRejected [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   paths logFile ensureCreateDirectory.
   self should: [ PuntPrivateFile open: paths logFile ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testFileSymlinkRejected [
 self withHomeDo: [ :paths |
   | target |
   paths ensureDirectories.
   target := sandbox / 'target-file'.
   target writeStreamDo: [ :stream | stream nextPutAll: 'untouched' ].
   self assert: (libc symlink: target pathString to: paths logFile pathString) equals: 0.
   self should: [ PuntPrivateFile open: paths logFile ] raise: PuntPermissionError.
   self assert: target contents equals: 'untouched'.
   paths logFile delete ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testForeignFileOwnerRejected [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   self should: [ PuntPrivateFile open: paths logFile using: PuntForeignOwnerLibC new ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testNewAndExistingFileModes [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   { paths logFile. paths lockFile. paths logsDirectory / 'sample-tool.log.1' } do: [ :path |
     | file |
     file := PuntPrivateFile open: path.
     [ self assert: file metadata permissions equals: 8r600 ] ensure: [ file close ].
     File file: path pathString posixPermissions: 8r666.
     file := PuntPrivateFile open: path.
     [ self assert: file metadata permissions equals: 8r600 ] ensure: [ file close ] ] ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testNonblockingLock [
 self withHomeDo: [ :paths |
   | first second |
   paths ensureDirectories.
   first := PuntPrivateFile open: paths lockFile.
   second := PuntPrivateFile open: paths lockFile.
   [ self assert: (libc tryLock: first descriptor) equals: 0.
     self assert: (libc tryLock: second descriptor) equals: -1.
     self assert: (libc unlock: first descriptor) equals: 0.
     self assert: (libc tryLock: second descriptor) equals: 0.
     libc unlock: second descriptor ] ensure: [ first close. second close ] ]
]

{ #category : 'tests' }
PuntPrivateFileTest >> testRenameLinkAndUnlink [
 self withHomeDo: [ :paths |
   | file destination linked |
   paths ensureDirectories.
   file := PuntPrivateFile open: paths logFile.
   file close.
   destination := paths logsDirectory / 'moved'.
   linked := paths logsDirectory / 'linked'.
   self assert: (libc rename: paths logFile pathString to: destination pathString) equals: 0.
   self assert: (libc link: destination pathString to: linked pathString) equals: 0.
   self assert: (libc stat: destination pathString) inode equals: (libc stat: linked pathString) inode.
   self assert: (libc unlink: linked pathString) equals: 0 ]
]
