# Grafana Dashboard Conventions

Dashboards in this tree are provisioned by `srv-lx-beacon` and grouped by folder from the file structure.

Use one baseline dashboard per platform or service class for golden signals, then add workload-specific dashboards beside it when they need domain language. For databases, the baseline should answer:

- Is the exporter up?
- Are connections healthy?
- Is transaction throughput normal?
- Are errors, rollbacks, deadlocks, or locks rising?
- Is latency or long-running activity increasing?
- Is storage growth visible?

Workload dashboards, such as Temporal, should show the application view of the same system. For Temporal that means service latency, persistence latency, task queues, pollers, SDK worker metrics, and logs. The Postgres dashboard remains the database engine view.
