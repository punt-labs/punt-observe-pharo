| suite result |
suite := TestSuite new.
(Smalltalk globals allClasses select: [ :each |
  each isTestCase and: [ each package name beginsWith: 'PuntObserve-' ] ])
  do: [ :each | suite addTests: each buildSuite tests ].
suite tests ifEmpty: [ self error: 'No PuntObserve tests loaded' ].
result := suite run.
String streamContents: [ :stream |
  stream nextPutAll: 'Tests: '; print: result runCount;
    nextPutAll: '  Passed: '; print: result passedCount;
    nextPutAll: '  Failures: '; print: result failureCount;
    nextPutAll: '  Errors: '; print: result errorCount; cr.
  result defects do: [ :each | stream print: each; cr ].
  result hasPassed ifTrue: [ stream nextPutAll: 'PUNT-OK' ] ]
