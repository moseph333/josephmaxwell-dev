---
title: "Automating Hardware Asset Tracking with Go and REST APIs"
date: 2026-09-30
description: "How I replaced a manual ticketing bottleneck with a structured Go web tool that brought visibility and consistency to datacenter hardware request workflows."
tags: ["Go", "automation", "datacenter", "tooling", "REST APIs"]
---

In any large-scale datacenter operation, the gap between "I need this hardware" and "hardware is where it should be" is often bridged by... a spreadsheet. Or worse, an email chain. I found myself in that exact situation — watching hardware request tracking generate inconsistencies, dropped handoffs, and wasted technician time.

So I built a fix.

## The Problem

Tracking hardware requests manually — even with a structured ticket system — introduces friction at every step. Fields get filled in inconsistently. Status updates fall through. The next technician to touch a task has no reliable history to work from.

For a team responsible for physical hardware across a busy facility, this creates real cost: technician time chasing status, duplicate work, and errors that compound across a shift.

## The Approach: A Go Web Tool with a REST API

I chose **Go** for a few reasons:

1. **Fast compilation and lightweight binaries** — easy to deploy on existing infrastructure without heavy runtime dependencies
2. **Strong standard library for HTTP servers** — `net/http` handles the web layer cleanly without needing a framework
3. **Straightforward concurrency** — Go's goroutine model made handling concurrent requests simple and predictable

The tool exposed a REST API that served as the single source of truth for hardware request state. Each request had a structured lifecycle: initiated → assigned → in-progress → resolved. Every state transition was logged.

```go
// Simplified example of a status update handler
func updateRequestStatus(w http.ResponseWriter, r *http.Request) {
    id := extractID(r)
    var update StatusUpdate
    if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
        http.Error(w, "bad request", http.StatusBadRequest)
        return
    }
    if err := store.Transition(id, update.Status, update.Note); err != nil {
        http.Error(w, err.Error(), http.StatusConflict)
        return
    }
    w.WriteHeader(http.StatusOK)
}
```

The web frontend (served by the same Go binary) gave technicians a simple dashboard: current open requests, their status, who owns them, and a timestamped history.

## Runbooks as Living Documentation

A secondary feature that ended up being just as valuable: **regional runbooks** published directly from the tool. Rather than living in a separate wiki that went stale, runbooks were version-controlled alongside the codebase and rendered as part of the web UI.

When a procedure changed, the runbook update went through the same review process as a code change. This kept documentation honest.

## What It Changed

The shift from manual tracking to the tool was measurable immediately:

- **Reduced dropped handoffs** — every state change had a named owner and timestamp
- **Faster onboarding** — new technicians could see current state and history without asking someone
- **Consistent vocabulary** — structured fields eliminated the ambiguity of free-text status notes

## Lessons for Datacenter Tooling

If you're thinking about building something similar, a few things I'd emphasize:

**Start with the workflow, not the code.** The most important design work happened before I wrote a line of Go — mapping out exactly what states a request could be in, what transitions were legal, and who could perform them.

**Lightweight is a feature.** A tool that's simple to run and deploy gets used. A tool that requires infrastructure setup gets abandoned.

**Make the runbooks part of the code.** Documentation that lives next to the thing it documents is documentation that stays current.

---

*Interested in datacenter tooling, hardware operations, or Linux infrastructure? Follow me on [LinkedIn](https://www.linkedin.com/in/josephrmaxwell/) or check out my self-hosting tutorials at [selfhostdojo.com](https://selfhostdojo.com).*
