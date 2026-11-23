"
PHARO-LOG-3: isolated roots and distinct working directories verify exact machine paths and private permissions, including rejection paths.

  self new
  >>> a PuntHomeTest
"
Class {
	#name : 'PuntHomeTest',
	#superclass : 'TestCase',
	#instVars : [
		'sandbox',
		'home',
		'libc'
	],
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'running' }
PuntHomeTest >> setUp [
 super setUp.
 sandbox := FileSystem disk workingDirectory / '.tmp' / ('core-test-' , UUID new asString).
 sandbox ensureCreateDirectory.
 home := sandbox / 'home'.
 home ensureCreateDirectory.
 libc := PuntLibC new
]

{ #category : 'running' }
PuntHomeTest >> tearDown [
 sandbox ensureDeleteAll.
 super tearDown
]

{ #category : 'tests' }
PuntHomeTest >> testDeniedDirectoryTightening [
 self withHomeDo: [ :paths |
   paths ensureDirectories; libc: PuntFailingLibC new.
   self should: [ paths ensureDirectories ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntHomeTest >> testDirectorySymlinkRejected [
 | target link |
 target := sandbox / 'target'.
 target ensureCreateDirectory.
 link := home / '.punt-labs'.
 self assert: (libc symlink: target pathString to: link pathString) equals: 0.
 self withHomeDo: [ :paths | self should: [ paths ensureDirectories ] raise: PuntPermissionError ].
 link delete
]

{ #category : 'tests' }
PuntHomeTest >> testExactPathsFromDifferentWorkingDirectories [
 | original |
 original := FileSystem disk workingDirectory.
 [ #( 'first' 'second' ) do: [ :name |
   | directory |
   directory := sandbox / name.
   directory ensureCreateDirectory.
   self assert: (libc chdir: directory pathString) equals: 0.
   self withHomeDo: [ :paths |
     self assert: paths logsDirectory equals: home / '.punt-labs' / 'sample-tool' / 'logs'.
     self assert: paths logFile basename equals: 'sample-tool.log'.
     self assert: paths lockFile basename equals: 'sample-tool.log.rotate.lock'.
     self assert: paths databaseFile equals: home / '.punt-labs' / 'sample-tool' / 'telemetry.db'.
     self assert: paths saltFile equals: home / '.punt-labs' / 'telemetry.salt' ] ] ]
   ensure: [ libc chdir: original pathString ]
]

{ #category : 'tests' }
PuntHomeTest >> testExistingDirectoriesIgnoreStaleErrnoAndCopyTool [
 | name paths |
 name := 'sample-tool' copy.
 paths := PuntHome duringHome: home do: [ PuntHome forTool: name ].
 paths ensureDirectories. paths libc: PuntStaleErrnoLibC new. paths ensureDirectories.
 name at: 1 put: $x.
 self assert: paths tool equals: 'sample-tool'.
 self assert: (libc stat: paths logsDirectory pathString) permissions equals: 8r700
]

{ #category : 'tests' }
PuntHomeTest >> testFileInPlaceOfDirectoryRejected [
 (home / '.punt-labs') writeStreamDo: [ :stream | stream nextPutAll: 'not a directory' ].
 self withHomeDo: [ :paths | self should: [ paths ensureDirectories ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntHomeTest >> testForeignDirectoryOwnerRejected [
 self withHomeDo: [ :paths |
   paths ensureDirectories; libc: PuntForeignOwnerLibC new.
   self should: [ paths ensureDirectories ] raise: PuntPermissionError ]
]

{ #category : 'tests' }
PuntHomeTest >> testInvalidToolNames [
 { ''. 'Upper'. '../x'. 'a/b'. '-tool'. 'a_b'. ('a' repeat: 65). 'é' } do: [ :name |
   self should: [ PuntHome forTool: name ] raise: PuntPermissionError ].
 self assert: (PuntHome forTool: ('a' repeat: 64)) tool size equals: 64
]

{ #category : 'tests' }
PuntHomeTest >> testNewAndExistingDirectoriesArePrivate [
 self withHomeDo: [ :paths |
   paths ensureDirectories.
   { paths labsDirectory. paths toolDirectory. paths logsDirectory } do: [ :directory |
     self assert: (libc stat: directory pathString) permissions equals: 8r700.
     File file: directory pathString posixPermissions: 8r777 ].
   paths ensureDirectories.
   { paths labsDirectory. paths toolDirectory. paths logsDirectory } do: [ :directory |
     self assert: (libc stat: directory pathString) permissions equals: 8r700 ] ]
]

{ #category : 'tests' }
PuntHomeTest >> testOverrideRestoredAfterFailure [
 | original |
 original := (PuntHome forTool: 'sample-tool') root.
 self should: [ PuntHome duringHome: home do: [ self error: 'test' ] ] raise: Error.
 self assert: (PuntHome forTool: 'sample-tool') root equals: original
]

{ #category : 'private' }
PuntHomeTest >> withHomeDo: aBlock [ ^ PuntHome duringHome: home do: [ aBlock value: (PuntHome forTool: 'sample-tool') ]
]
