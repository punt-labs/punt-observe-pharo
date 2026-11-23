"
PHARO-LOG-3, PHARO-LOG-4: descriptor metadata copied from the platform stat ABI.

  PuntFileStat new mode: 8r100600; isRegular
  >>> true
"
Class {
	#name : 'PuntFileStat',
	#superclass : 'Object',
	#instVars : [
		'inode',
		'mode',
		'size',
		'uid'
	],
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}

{ #category : 'accessing' }
PuntFileStat >> inode [ ^ inode
]

{ #category : 'accessing' }
PuntFileStat >> inode: anInteger [ inode := anInteger
]

{ #category : 'testing' }
PuntFileStat >> isDirectory [ ^ (mode bitAnd: 8r170000) = 8r40000
]

{ #category : 'testing' }
PuntFileStat >> isRegular [ ^ (mode bitAnd: 8r170000) = 8r100000
]

{ #category : 'testing' }
PuntFileStat >> isSymbolicLink [ ^ (mode bitAnd: 8r170000) = 8r120000
]

{ #category : 'accessing' }
PuntFileStat >> mode [ ^ mode
]

{ #category : 'accessing' }
PuntFileStat >> mode: anInteger [ mode := anInteger
]

{ #category : 'accessing' }
PuntFileStat >> permissions [ ^ mode bitAnd: 8r7777
]

{ #category : 'accessing' }
PuntFileStat >> size [ ^ size
]

{ #category : 'accessing' }
PuntFileStat >> size: anInteger [ size := anInteger
]

{ #category : 'accessing' }
PuntFileStat >> uid [ ^ uid
]

{ #category : 'accessing' }
PuntFileStat >> uid: anInteger [ uid := anInteger
]
