| root upstream local |
root := (OSEnvironment current at: 'PUNT_OBSERVE_ROOT') asFileReference.
upstream := root / '.tmp' / 'upstream'.
local := [ :directory | 'gitlocal://' , directory pathString , '/src' ].
Metacello new baseline: 'Postern'; repository: (local value: upstream / 'postern'); load.
Metacello new baseline: 'SQLite3'; repository: (local value: upstream / 'sqlite'); load: 'Core'.
Metacello new baseline: 'GRPC'; repository: (local value: upstream / 'grpc'); load.
Metacello new baseline: 'PharoBackwardCompatibility'; repository: (local value: upstream / 'compat'); load.
Metacello new baseline: 'OpenTelemetry'; repository: (local value: upstream / 'otel'); onConflictUseLoaded; load: #('traces' 'metrics').
Metacello new baseline: 'PuntObserve'; repository: 'tonel://' , (root / 'src') pathString; onConflictUseLoaded; load: 'all'.
Smalltalk snapshot: true andQuit: true.
