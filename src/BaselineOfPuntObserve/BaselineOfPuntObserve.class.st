"
PHARO-LOG-1, PHARO-TEL-1: package graph only, with no logging or telemetry startup. External dependencies are pinned; instrumentation plugins are excluded.

  self new
  >>> a BaselineOfPuntObserve
"
Class {
	#name : 'BaselineOfPuntObserve',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPuntObserve',
	#package : 'BaselineOfPuntObserve'
}

{ #category : 'baselines' }
BaselineOfPuntObserve >> baseline: spec [
 <baseline>
 spec for: #common do: [
   self dependencies: spec.
   self packages: spec.
   self groups: spec ]
]

{ #category : 'baselines' }
BaselineOfPuntObserve >> dependencies: spec [
   spec baseline: 'SQLite3' with: [ spec repository: 'github://pharo-rdbms/Pharo-SQLite3:44dee155676f9ac9be1c7ffac8caef90024968c4/src'; loads: 'Core' ].
   spec baseline: 'OpenTelemetry' with: [ spec repository: 'github://Gabriel-Darbord/opentelemetry-pharo:2f5f61c093216309eef43e48211477cceaf0cff7/src'; loads: #('traces' 'metrics') ]
]

{ #category : 'baselines' }
BaselineOfPuntObserve >> groups: spec [
   spec group: 'default' with: #('PuntObserve-Core' 'PuntObserve-Logging' 'PuntObserve-Telemetry').
   spec group: 'tests' with: #('PuntObserve-Core-Tests' 'PuntObserve-Logging-Tests' 'PuntObserve-Telemetry-Tests').
   spec group: 'smoke' with: 'PuntObserve-Smoke'.
   spec group: 'all' with: #('default' 'tests' 'smoke')
]

{ #category : 'baselines' }
BaselineOfPuntObserve >> packages: spec [
   spec package: 'PuntObserve-Core'.
   spec package: 'PuntObserve-Logging' with: [ spec requires: 'PuntObserve-Core' ].
   spec package: 'PuntObserve-Telemetry' with: [ spec requires: #('PuntObserve-Core' 'PuntObserve-Logging' 'SQLite3' 'OpenTelemetry') ].
   spec package: 'PuntObserve-Smoke' with: [ spec requires: #('PuntObserve-Logging' 'PuntObserve-Telemetry') ].
   spec package: 'PuntObserve-Core-Tests' with: [ spec requires: 'PuntObserve-Core' ].
   spec package: 'PuntObserve-Logging-Tests' with: [ spec requires: 'PuntObserve-Logging' ].
   spec package: 'PuntObserve-Telemetry-Tests' with: [ spec requires: #('PuntObserve-Telemetry' 'PuntObserve-Core-Tests') ]
]
