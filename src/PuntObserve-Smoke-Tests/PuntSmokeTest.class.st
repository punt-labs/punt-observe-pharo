"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: Detached smoke artifact preparation rejects stale success markers. Object subclasses represent explicit service or value boundaries.

  PuntSmokeTest new class name
  >>> #PuntSmokeTest
"
Class {
	#name : 'PuntSmokeTest',
	#superclass : 'PuntHomeTest',
	#category : 'PuntObserve-Smoke-Tests',
	#package : 'PuntObserve-Smoke-Tests'
}

{ #category : 'tests' }
PuntSmokeTest >> testChildFilesCannotReuseStaleSuccess [
 | smoke files |
 smoke := PuntTestSmoke new reportFile: sandbox / 'result.json'.
 files := smoke childFiles.
 files first writeStreamDo: [ :stream | stream nextPutAll: 'complete' ].
 files second writeStreamDo: [ :stream | stream nextPutAll: '{"outcome":"ok"}' ].
 self assert: smoke prepareChildFiles equals: files.
 self deny: (files anySatisfy: [ :file | file exists ]).
 self assert: smoke prepareChildFiles equals: files.
 self deny: (files anySatisfy: [ :file | file exists ])
]
