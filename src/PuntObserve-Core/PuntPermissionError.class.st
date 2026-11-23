"
PHARO-LOG-3, PHARO-TEL-3: a private filesystem operation failed. No fallback path is permitted.

  [ PuntPermissionError signal ] on: PuntPermissionError do: [ :error | error return: true ]
  >>> true
"
Class {
	#name : 'PuntPermissionError',
	#superclass : 'Error',
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}
