# Changelog

## Unreleased

- Fix private-file reopen decisions under same-thread uFFI errno clobbering;
  count categorized logging drops and assert zero drops in each image writer.
- Add typed versioned telemetry, pre-enqueue HMAC identifier derivation,
  atomically published private salt, bounded worker and session vetoes.
- Add private SQLite span/metric persistence, timer-based retention and explicit
  OTLP HTTP consent, plus privacy, failure and independent-image SQLite gates.
- Add typed Beacon diagnostics, complete-record redaction, private rotating
  sinks, session lifecycle, Zinc bridge and correlated background-work helpers.
- Add reusable consumer source gates and independent-image concurrency,
  retention, privacy, permission and lock-budget acceptance tests.
- Add private machine-scoped paths, descriptor-based permission tightening,
  nonblocking locks and Unicode single-line escaping.
- Add pinned dependency bootstrap, baseline groups, isolated SUnit tests and CI.
