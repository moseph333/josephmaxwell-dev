---
title: "Automating Hardware Asset Tracking with Go and REST APIs"
date: 2026-09-30
draft: true
description: "How I replaced a manual ticketing bottleneck with a structured Go web tool that brought visibility and consistency to datacenter hardware request workflows."
tags: ["Go", "automation", "datacenter", "tooling", "REST APIs"]
---

In a busy datacenter facility, tracking hardware requests through spreadsheets or free-text tickets inevitably causes dropped handoffs and lost shift hours. Technicians spend time verifying whether a part was staged, installed, or sent to sanitization instead of doing hardware turn-up.

To fix that friction in our workflow, I built a lightweight internal web service in Go backed by a REST API.

## The Problem

Manual request tracking breaks down in predictable ways across shift rotations:

- **Inconsistent status reporting:** Without rigid schemas, technicians use different terms for the same state, leaving the incoming shift guessing.
- **Lost context:** Ticket comment threads bury part serial numbers and rack location changes.
- **Wasted triage time:** Technicians walk the floor or ping chat channels just to check whether hardware arrived at the row.

## Why Go for Facility Tooling

I chose Go for three practical operational reasons:

1. **Self-contained deployment:** Compiling to a single static binary made installation and running on local linux bastions trivial, with zero runtime dependency management.
2. **Standard library HTTP:** The built-in `net/http` package handled the routing and JSON serialization without adding third-party framework overhead.
3. **Predictable concurrency:** Handling simultaneous updates from technicians on the datacenter floor was straightforward using standard goroutines and sync primitives.

The service exposed a REST API with an explicit request lifecycle: `initiated` → `assigned` → `in-progress` → `resolved`. Every transition required an authenticated technician ID and logged the timestamp to an append-only store.

```go
// Example of a validated status transition handler
func updateRequestStatus(w http.ResponseWriter, r *http.Request) {
    id := extractID(r)
    var update StatusUpdate
    if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
        http.Error(w, "invalid request body", http.StatusBadRequest)
        return
    }
    if err := store.Transition(id, update.Status, update.Note); err != nil {
        http.Error(w, err.Error(), http.StatusConflict)
        return
    }
    w.WriteHeader(http.StatusOK)
}
```

The web dashboard served by the same binary gave the floor leads real-time visibility into open hardware pulls, assigned owners, and pending sanitization batches.

## Co-locating Runbooks with the Tool

Regional runbooks were embedded directly into the tool rather than hosted on an external wiki. Because the markdown runbooks lived in the same git repository as the Go service, procedure updates went through the exact same peer review and deployment workflow as application code.

When a hardware RMA procedure changed, the runbook was updated in the commit that supported it.

## Results

Putting an explicit API in front of hardware requests produced immediate operational benefits:

- **Zero ambiguous handoffs:** Every status change recorded a verified technician and timestamp.
- **Faster shift transitions:** Incoming technicians reviewed the dashboard queue in two minutes instead of asking for status over chat.
- **Audit-ready records:** Decommissioned drives and hardware swaps retained clean logs for compliance audits.

## Practical Takeaways

- **Define legal state transitions first:** The most valuable work was mapping out valid state progressions before writing handler code.
- **Single binaries win in production:** A tool that requires Python virtualenvs or node_modules on an internal bastion gets neglected; a single static Go binary keeps running.
- **Version runbooks alongside code:** Documentation that shares the release lifecycle of your tools stays accurate.

---

Follow my work on [LinkedIn](https://www.linkedin.com/in/josephrmaxwell/) or read my self-hosting and Linux infrastructure guides on [selfhostdojo.com](https://selfhostdojo.com).
