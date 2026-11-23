"
PHARO-LOG-5: Acceptance fixture for PHARO-LOG-5; deterministic isolation of logging behavior.

  PuntLogRedactorTest new class name
  >>> #PuntLogRedactorTest
"
Class {
	#name : 'PuntLogRedactorTest',
	#superclass : 'TestCase',
	#instVars : [
		'redactor'
	],
	#category : 'PuntObserve-Logging-Tests',
	#package : 'PuntObserve-Logging-Tests'
}

{ #category : 'running' }
PuntLogRedactorTest >> setUp [ super setUp. redactor := PuntLogRedactor new home: '/home/alice'
]

{ #category : 'tests' }
PuntLogRedactorTest >> testControlPatternsSurviveTonel [
 self assert: (redactor cleanRecord: 'Cookie: a=PRIVATE' , String cr , 'Visible') utf8Decoded equals: 'Cookie: [redacted]\x0dVisible' , String lf.
 self assert: (redactor cleanRecord: 'Cookie: a=PRIVATE' , String lf , 'Visible') utf8Decoded equals: 'Cookie: [redacted]\x0aVisible' , String lf.
 self assert: (redactor cleanRecord: (Character value: 16rd800) asString) isNil.
 self assert: (redactor cleanRecord: (Character value: 16r110000) asString) isNil
]

{ #category : 'tests' }
PuntLogRedactorTest >> testControlsAndUtf8ByteCap [
 | text |
 self assert: (redactor cleanRecord: 'a' , String lf , (Character value: 16r202e) asString) utf8Decoded equals: 'a\x0a\u202e' , String lf.
 text := String streamContents: [ :stream | 20000 timesRepeat: [ stream nextPutAll: 'é ' ] ].
 self assert: (redactor cleanRecord: text) size equals: 60001.
 self assert: (redactor cleanRecord: (String tab repeat: 20000)) isNil
]

{ #category : 'tests' }
PuntLogRedactorTest >> testCredentialLabelsAndCaptureNumbering [
 | matcher |
 matcher := PuntLogRegexMatcher forString: '(api_key=)([^ ]+)' ignoreCase: true.
 self assert: (matcher matches: 'api_key=SECRET').
 self assert: (matcher subexpression: 1) equals: 'api_key=SECRET'.
 self assert: (matcher subexpression: 2) equals: 'api_key='.
 { 'api_key=SECRET' -> 'api_key=[redacted]'.
   'Cookie: a=SECRET' -> 'Cookie: [redacted]'.
   'Set-Cookie: a=SECRET' -> 'Set-Cookie: [redacted]'.
   'Authorization: Basic SHORT' -> 'Authorization: [redacted]'.
   'Bearer SHORT' -> 'Bearer [redacted]' } do: [ :pair |
     self assert: (redactor cleanRecord: pair key) utf8Decoded equals: (String streamContents: [ :stream | stream nextPutAll: pair value; lf ]) ]
]

{ #category : 'tests' }
PuntLogRedactorTest >> testEmptyAndOpaqueAndCap [
 | text |
 self assert: (redactor cleanRecord: '') isNil.
 self assert: (redactor cleanRecord: ('a' repeat: 2049)) utf8Decoded equals: '[opaque]' , String lf.
 text := 'a ' repeat: 32767.
 self assert: (redactor cleanRecord: text) size equals: 65535.
 self assert: (redactor cleanRecord: text , 'a') size equals: 65536.
 self assert: (redactor cleanRecord: text , 'aa') isNil
]

{ #category : 'tests' }
PuntLogRedactorTest >> testFailureAndUnsettledWithheld [
 self assert: (PuntTestFailingRedactor new cleanRecord: 'safe') isNil.
 self assert: (PuntTestUnsettledRedactor new cleanRecord: 'safe') isNil
]

{ #category : 'tests' }
PuntLogRedactorTest >> testFormattedLiteralEscapesCannotSplitCredentials [
 | formatter |
 formatter := PuntLogFormatter new.
 #('Cookie: a=SECRET\x0ab=OTHER' 'password=PART1\x09PART2' 'password=PART1\\PART2') do: [ :input |
   | bytes text |
   bytes := redactor cleanEscapedRecord: (formatter format: (PuntLogSignal new component: 'test'; message: input)).
   self deny: bytes isNil.
   text := bytes utf8Decoded.
   self assert: (text includesSubstring: '[redacted]').
   #('SECRET' 'OTHER' 'PART1' 'PART2') do: [ :secret | self deny: (text includesSubstring: secret) ] ].
 self assert: (redactor cleanEscapedRecord: (formatter format: (PuntLogSignal new component: 'test'; message: 'literal \\')) ) utf8Decoded lines size equals: 1.
 self assert: (redactor restoreSpacing: (PuntEscaper escape: 'literal \\')) equals: 'literal \\'

]

{ #category : 'tests' }
PuntLogRedactorTest >> testGoPatterns [
 { 'https://u:p@host.test/path?q=secret#frag' -> '[url]'.
   'Cookie: a=SECRET; b=OTHER' -> 'Cookie: [redacted]'.
   'api_key=SECRET password="PRIVATE VALUE"' -> 'api_key=[redacted] password=[redacted]'.
   'Authorization: Bearer SECRET' -> 'Authorization: [redacted]'.
   'bearer SECRET' -> 'bearer [redacted]'.
   'ghp_abcdefghijklmnop' -> '[redacted]'.
   'github_pat_abcdefghijklmnop_' -> '[redacted]'.
   'épassword=PRIVATE' -> 'épassword=[redacted]'.
   'user:pass@host.test' -> '[userinfo]'.
   'alice@example.test' -> '[email]'.
   '/home/alice/private' -> '[path]'.
   'in /var/private' -> 'in [path]' } do: [ :pair |
     self assert: (redactor cleanRecord: pair key) utf8Decoded equals: (String streamContents: [ :stream | stream nextPutAll: pair value; lf ]) ]
]

{ #category : 'tests' }
PuntLogRedactorTest >> testUnicodeSeparatorsInRawAndEscapedCredentials [
 #(8232 8233) do: [ :code |
   | separator prefix input expected |
   separator := (Character value: code) asString.
   #('Bearer' 'Basic') do: [ :scheme |
     prefix := String streamContents: [ :stream | stream nextPutAll: scheme; nextPutAll: separator ].
     input := String streamContents: [ :stream | stream nextPutAll: prefix; nextPutAll: 'SHORTSECRET' ].
     expected := String streamContents: [ :stream |
       stream nextPutAll: (PuntEscaper escape: prefix); nextPutAll: '[redacted]'; lf ].
     self assert: (redactor cleanRecord: input) utf8Decoded equals: expected.
     self assert: (redactor cleanEscapedRecord: (PuntEscaper escape: input)) utf8Decoded equals: expected ] ]
]
