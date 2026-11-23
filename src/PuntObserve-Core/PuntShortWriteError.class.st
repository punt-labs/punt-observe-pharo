"
PHARO-LOG-4, PHARO-LOG-5: A single append did not write the complete record. Callers must not retry fragments; the sink counts a short-write drop.

  [ PuntShortWriteError signal ] on: PuntPermissionError do: [ :error | true ]
  >>> true
"
Class {
	#name : 'PuntShortWriteError',
	#superclass : 'PuntPermissionError',
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}
