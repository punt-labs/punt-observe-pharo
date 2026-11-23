| suite result details report |
suite := TestSuite new.
(Smalltalk globals allClasses select: [ :each |
  each isTestCase and: [ each package name beginsWith: 'PuntObserve-' ] ])
  do: [ :each | suite addTests: each buildSuite tests ].
suite tests ifEmpty: [ self error: 'No PuntObserve tests loaded' ].
result := TestResult new.
details := OrderedCollection new.
CurrentExecutionEnvironment runTestsBy: [
  suite runWith: [ :test |
    [ test announce: TestCaseStarted withResult: result.
      test runCaseManaged.
      test announce: TestCaseEnded withResult: result.
      result addPass: test ]
      on: result class failure , result class skip , result class warning , result class error
      do: [ :error |
        details add: test printString , ': ' , error description.
        error sunitAnnounce: test toResult: result ] ] ].
report := String streamContents: [ :stream |
  stream nextPutAll: 'Tests: '; print: result runCount;
    nextPutAll: '  Passed: '; print: result passedCount;
    nextPutAll: '  Failures: '; print: result failureCount;
    nextPutAll: '  Errors: '; print: result errorCount; cr.
  result defects do: [ :each | stream print: each; cr ].
  details do: [ :each | stream nextPutAll: each; cr ] ].
{ report. result hasPassed }
