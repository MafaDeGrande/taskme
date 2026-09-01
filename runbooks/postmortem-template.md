# Postmortem: [incident title]

> Use factual, blameless language. Describe the system conditions that shaped
> decisions rather than assigning fault to individuals.

Date: [YYYY-MM-DD]  
Start / resolution (UTC): [HH:MM / HH:MM]  
Duration: [minutes]  
Severity: [SEV level]  
On-call: [role or name]  
Incident commander: [role or name]  
Postmortem owner: [one accountable owner]  
Status: [draft / reviewed / complete]

## Summary

[In three to five sentences, describe what failed, the user impact, how it was
detected, the root cause, and how service was restored.]

## Impact

- Users or orders affected: [count or evidence-based estimate]
- Failed requests and peak error rate: [value and evidence]
- Latency impact: [p95/p99 and duration]
- Availability SLO budget burned: [minutes and percentage of 30-day budget]
- Billing or data-integrity impact: [none or confirmed impact]

## Timeline

Use UTC and include detection, mitigation, recovery, and resolution.

| Time | Phase | Event, evidence, or action |
|---|---|---|
| [HH:MM] | Detection | [...] |
| [HH:MM] | Mitigation | [...] |
| [HH:MM] | Resolution | [...] |

## Root cause analysis

Trigger: [Immediate event that exposed the failure.]
Root cause: [Evidence-based system or process cause.]
Contributing factors: [Conditions that increased probability, duration, or
impact.]

Use the Five Whys technique to trace the incident beyond the immediate failure
to the underlying system or process gap. Summarize the resulting causal chain in
one or two short paragraphs and support it with evidence.

## Lessons learned

What went well:

- [...]

What could be improved:

- [...]

Where we got lucky:

- [...]

## Action items

| ID | Action and measurable result | Type | Priority | Owner | Due date | Tracker | Status |
|---|---|---|---|---|---|---|---|
| [1] | [Specific verifiable change] | [prevent/detect/mitigate] | [P0-P2] | [owner] | [YYYY-MM-DD] | [link] | [open/done] |

## Evidence and review

- Incident channel or document: [link]
- Dashboard, logs, and relevant changes: [links]
- Reviewers and review date: [names, YYYY-MM-DD]
