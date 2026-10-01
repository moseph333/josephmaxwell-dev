---
title: "Automating Datacenter Logistics: From Apps Script to Go"
date: 2026-09-30
draft: true
description: "How building our facility's most popular hardware tracking workflow with Google Forms, Sheets, and Apps Script solved shift handoffs, and what I am taking forward as I learn Go."
tags: ["datacenter", "automation", "Apps Script", "Go", "tooling"]
---

In a busy datacenter facility, tracking hardware requests through unstructured chat pings or messy ticket threads inevitably causes dropped handoffs and lost shift hours. Technicians spend time walking rows or asking around to verify whether a part was staged, installed, or routed for physical destruction instead of doing hardware turn-up.

To eliminate that friction, I built a facility tracking system that quickly became our team's most widely adopted tool.

## The Problem

Manual request tracking breaks down across shift rotations in predictable ways:

- **Inconsistent status reporting:** Without rigid schemas, technicians describe the same status differently, leaving the incoming shift guessing.
- **Lost context:** Chat threads and free-text ticket notes bury part serial numbers, MAC addresses, and rack location updates.
- **Wasted triage time:** Incoming shift leads spend 20 to 30 minutes verifying the status of active requests instead of starting rack work.

## Meeting Technicians Where They Work

When building tools for operational teams, adoption beats architectural purity every time. Technicians on the datacenter floor don't want to authenticate against a separate web portal or maintain local dependencies.

I built the initial system using Google Forms, Google Sheets, and Google Apps Script:

1. **Structured intake with Google Forms:** The form enforced strict validation on asset serial numbers, target rack coordinates, component categories, and requester details.
2. **Automated state engine with Apps Script:** When an intake form was submitted, Apps Script validated the payload, stamped an immutable timestamp, assigned an initial state (`Staged`), and triggered notifications to on-duty leads.
3. **Real-time visibility in Sheets:** A locked summary sheet served as a live floor dashboard, color-coding aging requests and recording every state transition.

Because the tool lived inside tools the team already used daily, adoption was immediate. It resolved ambiguity between shifts and became the standard workflow for tracking facility hardware requests.

## Why I Am Learning Go

Building the Apps Script tool proved how valuable clean state machines and structured schemas are to floor operations. As I started exploring ways to integrate directly with local Linux bastions, parse hardware logs, and build lightweight CLI utilities, Go became the clear next language to learn.

A few operational characteristics make Go appealing for datacenter infrastructure:

- **Single static binaries:** A compiled Go binary runs on a bastion host with zero dependencies—no Python virtual environments or runtime managers to maintain across machines.
- **Standard library power:** Go's `net/http` and `encoding/json` packages make building internal APIs or calling external webhooks straightforward without pulling in dozens of third-party libraries.
- **Strong typing and clear concurrency:** Go's strict types catch data model errors at compile time, and goroutines make handling simultaneous floor queries predictable.

Here is an example pattern from my current Go learning projects, modeling the same validated status transitions that made the Apps Script tool reliable:

```go
// Example of a validated status transition handler in Go
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

## Practical Takeaways

- **Adoption comes from low friction:** The best tool is the one technicians actually use during a high-pressure maintenance window.
- **Define legal state transitions first:** Mapping valid states (`Staged` → `In-Transit` → `Installed` → `Decommissioned`) mattered far more than the specific programming language.
- **Automate what hurts:** Solving shift handoffs saved real technician hours every week and created clean audit trails for hardware tracking.

---

Follow my work on [LinkedIn](https://www.linkedin.com/in/josephrmaxwell/) or read my self-hosting and Linux infrastructure guides on [selfhostdojo.com](https://selfhostdojo.com).
