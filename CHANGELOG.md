## Changelog
### v0.4.3
- Adds ability to generate metrics modules via `prometheus_telemetry.gen.metrics`

### v0.4.2
- Fix issue with max_idle time disconnect metrics from Finch

### v0.4.1
- Fix issue that caused metrics to crash if no known query module attached

### v0.4.0
- phoenix.endpoint_call.count metric for calls
- clamp ecto query to 150 chars by default
- add ability to set KnownQuerys module
- add ability to set known query in repo call

### v0.3.2
- Add response code count for statuses

### v0.3.1
- Make sure we transform all keys to strings for gql metrics to avoid collisions

### v0.3.0
- Swap microseconds to millseconds globally
- Change default microsecond buckets

### v0.2.8
- Expose method on finch metrics

### v0.2.7
- Add additional swoosh info
- Add additional finch metric info

### v0.2.6
- Fix mailer naming for swoosh

### v0.2.5
- Add a case for when regex fails to parse gql names
- Relax dependency requirements

### v0.2.4
- Add finch metrics
- Add cowboy metrics
- Add swoosh metrics

### v0.2.3
- Fix oban metrics

### v0.2.2
- Add oban metrics

### v0.2.1
- Add vm metrics that aren't periodic
- Make sure all apps are required only if lib is found
- Fix graphql request_name

### v0.2.0
- Add periodic measurements and add a Beam Uptime metric

### v0.1.0
- Initial Release
