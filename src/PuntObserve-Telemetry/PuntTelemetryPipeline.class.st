"
PHARO-TEL-1, PHARO-TEL-2, PHARO-TEL-3, PHARO-TEL-4, PHARO-TEL-5: One worker owns private SDK providers, delta collection and config-only SQLite versus protobuf OTLP selection. Object subclasses represent explicit service or value boundaries.

  PuntTelemetryPipeline new class name
  >>> #PuntTelemetryPipeline
"
Class {
	#name : 'PuntTelemetryPipeline',
	#superclass : 'Object',
	#instVars : [
		'traces',
		'metrics',
		'reader',
		'spanExporter',
		'metricExporter',
		'store'
	],
	#category : 'PuntObserve-Telemetry',
	#package : 'PuntObserve-Telemetry'
}

{ #category : 'operating' }
PuntTelemetryPipeline >> abort [ store ifNotNil: [ store close ]. traces := nil. metrics := nil. reader := nil
]

{ #category : 'operating' }
PuntTelemetryPipeline >> close [
 [ traces ifNotNil: [ traces shutdown ]. metrics ifNotNil: [ metrics shutdown ]. metricExporter ifNotNil: [ metricExporter shutdown ] ]
   ensure: [ store ifNotNil: [ store close ] ]
]

{ #category : 'operating' }
PuntTelemetryPipeline >> collect [
 | snapshot |
 snapshot := reader collectSnapshot.
 snapshot metrics ifNotEmpty: [ metricExporter export: snapshot ]
]

{ #category : 'private' }
PuntTelemetryPipeline >> configureOtlp: config [
 spanExporter := OTOtlpHttpProtobufSpanExporter configuration: (self otlpConfiguration: config signal: 'traces').
 metricExporter := OTOtlpHttpProtobufMetricExporter configuration: (self otlpConfiguration: config signal: 'metrics').
 spanExporter maxExportAttempts: 1; warningSink: [ :message | PuntTelemetryDiagnostics noteFailure ].
 metricExporter maxExportAttempts: 1; warningSink: [ :message | PuntTelemetryDiagnostics noteFailure ]
]

{ #category : 'private' }
PuntTelemetryPipeline >> configureProvidersFor: tool [
 | resource processor |
 resource := OTResource attributes: { 'service.name' -> tool }.
 traces := OTTracerProvider new. traces resource: resource.
 processor := OTSimpleSpanProcessor new.
 processor exporter: spanExporter; exportTimeoutMillis: 0.
 traces addSpanProcessor: processor.
 metrics := OTMeterProvider new. metrics resource: resource.
 reader := OTInMemoryMetricReader new.
 reader temporalitySelector: [ :instrument | #delta ].
 metrics addMetricReader: reader.
 ^ self
]

{ #category : 'initialization' }
PuntTelemetryPipeline >> home: home config: config [
 [ config usesOtlp ifTrue: [ self configureOtlp: config ] ifFalse: [
     store := PuntTelemetryStore new home: home retentionDays: config retentionDays.
     spanExporter := PuntSQLiteSpanExporter new store: store.
     metricExporter := PuntSQLiteMetricExporter new store: store ].
   spanExporter := PuntTelemetrySpanExporter new delegate: spanExporter.
   metricExporter := PuntTelemetryMetricExporter new delegate: metricExporter.
   self configureProvidersFor: home tool
 ] ifCurtailed: [ self abort ].
 ^ self
]

{ #category : 'accessing' }
PuntTelemetryPipeline >> metricExporter [ ^ metricExporter
]

{ #category : 'accessing' }
PuntTelemetryPipeline >> metrics [ ^ metrics
]

{ #category : 'private' }
PuntTelemetryPipeline >> otlpConfiguration: config signal: signal [
 | endpoint |
 endpoint := config otlpEndpoint.
 [ endpoint endsWith: '/' ] whileTrue: [ endpoint := endpoint allButLast ].
 ^ OTOtlpExporterConfiguration new endpoint: endpoint , '/v1/' , signal; protocol: 'http/protobuf'; timeoutMillis: 500; yourself
]

{ #category : 'operating' }
PuntTelemetryPipeline >> prune [ store ifNotNil: [ store prune ]
]

{ #category : 'operating' }
PuntTelemetryPipeline >> record: record [
 (#(span event) includes: record kind) ifTrue: [ ^ self recordSpan: record ].
 self recordMetric: record
]

{ #category : 'private' }
PuntTelemetryPipeline >> recordMetric: record [
 | meter instrument |
 meter := metrics meterNamed: 'punt.metrics'.
 record kind = #counter ifTrue: [
   instrument := meter counterNamed: record name unit: record unit description: ''.
   instrument add: record amount attributes: record attributes.
   ^ self ].
 instrument := meter histogramNamed: record name unit: record unit description: ''.
 instrument record: record amount attributes: record attributes
]

{ #category : 'private' }
PuntTelemetryPipeline >> recordSpan: record [
 | span attributes tracer |
 tracer := traces tracerNamed: (record kind = #event ifTrue: [ 'punt.events' ] ifFalse: [ 'punt.spans' ]).
 attributes := record attributes copy.
 attributes at: 'punt.signal.kind' put: record kind asString.
 span := (tracer spanBuilderNamed: record name) asRoot; attributes: attributes; startTimestamp: record startedAt; startSpan.
 record kind = #event ifTrue: [ span addEventNamed: record name attributes: record attributes timestamp: record startedAt ].
 span end: record endedAt
]

{ #category : 'accessing' }
PuntTelemetryPipeline >> spanExporter [ ^ spanExporter
]

{ #category : 'accessing' }
PuntTelemetryPipeline >> store [ ^ store
]

{ #category : 'accessing' }
PuntTelemetryPipeline >> traces [ ^ traces
]
