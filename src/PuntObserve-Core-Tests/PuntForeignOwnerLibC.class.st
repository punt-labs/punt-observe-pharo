"
PHARO-LOG-3: simulate another owner without requiring root.

  self new
  >>> a PuntForeignOwnerLibC
"
Class {
	#name : 'PuntForeignOwnerLibC',
	#superclass : 'PuntLibC',
	#category : 'PuntObserve-Core-Tests',
	#package : 'PuntObserve-Core-Tests'
}

{ #category : 'accessing' }
PuntForeignOwnerLibC >> fstat: aDescriptor [ ^ (super fstat: aDescriptor) uid: self getuid + 1; yourself
]
