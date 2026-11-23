"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Stateless OS entropy and atomic link publication; no salt instance or class cache survives a snapshot. Object subclasses represent explicit service or value boundaries.

  PuntTelemetrySalt new class name
  >>> #PuntTelemetrySalt
"
Class {
	#name : 'PuntTelemetrySalt',
	#superclass : 'Object',
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'private' }
PuntTelemetrySalt >> entropy [
 | libc fd bytes |
 libc := PuntLibC new. bytes := ByteArray new: 32.
 fd := libc open: '/dev/urandom' flags: libc noFollowFlag mode: 0.
 fd < 0 ifTrue: [ PuntPermissionError signal: 'Cannot open system entropy' ].
 [ (libc read: fd bytes: bytes count: 32) = 32 ifFalse: [ PuntPermissionError signal: 'Cannot read system entropy' ] ] ensure: [ libc close: fd ].
 ^ bytes
]

{ #category : 'converting' }
PuntTelemetrySalt >> hash: aString home: home [ ^ (SHA256 new hmac key: (self readAt: home); digestMessage: aString utf8Encoded) hex
]

{ #category : 'private' }
PuntTelemetrySalt >> publishAt: home [
 | libc temporary descriptor |
 libc := PuntLibC new.
 temporary := home labsDirectory / ('telemetry.salt.' , UUID new asString).
 descriptor := libc open: temporary pathString flags: libc createFlags mode: 8r600.
 descriptor < 0 ifTrue: [ PuntPermissionError signal: 'Cannot prepare private salt' ].
 [ [ | bytes | libc secure: descriptor directory: false. bytes := self entropy.
     (libc write: descriptor bytes: bytes count: 32) = 32 ifFalse: [ PuntPermissionError signal: 'Cannot write private salt' ] ] ensure: [ libc close: descriptor ].
   (libc link: temporary pathString to: home saltFile pathString) = 0 ifFalse: [
     libc errno = 17 ifFalse: [ PuntPermissionError signal: 'Cannot publish private salt' ] ]
 ] ensure: [ libc unlink: temporary pathString ]
]

{ #category : 'accessing' }
PuntTelemetrySalt >> readAt: home [
 | libc fd bytes |
 home ensureDirectories. libc := PuntLibC new.
 [ libc stat: home saltFile pathString ] on: PuntPermissionError do: [ :error |
   libc errno = 2 ifTrue: [ self publishAt: home ] ifFalse: [ error pass ] ].
 fd := libc open: home saltFile pathString flags: libc noFollowFlag mode: 0.
 fd < 0 ifTrue: [ PuntPermissionError signal: 'Cannot read private salt' ].
 bytes := ByteArray new: 32.
 [ libc secure: fd directory: false.
   (libc fstat: fd) size = 32 ifFalse: [ PuntPermissionError signal: 'Invalid private salt' ].
   (libc read: fd bytes: bytes count: 32) = 32 ifFalse: [ PuntPermissionError signal: 'Incomplete private salt' ]
 ] ensure: [ libc close: fd ].
 ^ bytes
]
