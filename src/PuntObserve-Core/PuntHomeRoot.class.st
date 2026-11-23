"
PHARO-LOG-3: process-scoped home override for isolated tests; production resolves FileLocator home.

  PuntHomeRoot value: nil during: [ PuntHomeRoot value ]
  >>> nil
"
Class {
	#name : 'PuntHomeRoot',
	#superclass : 'DynamicVariable',
	#category : 'PuntObserve-Core',
	#package : 'PuntObserve-Core'
}
