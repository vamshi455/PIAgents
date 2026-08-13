# PIAgents documentation index

Start with the root [README.md](../README.md) for a high-level product summary.  
Use this index when you need **operations-grade detail**.

## For operations (primary)

| Document | Audience | Contents |
|---|---|---|
| [Operations handbook](operations/00_handbook.md) | All ops / platform | Master guide: purpose, diagrams, current state, ownership |
| [End-to-end data flow](operations/01_end_to_end_flow.md) | Pipeline / data eng | Line-by-line path from PI mock → Genie/agents |
| [Mock PI API runbook](operations/02_mock_pi_api.md) | App / platform | Local API, endpoints, tunnel, env vars |
| [Databricks setup runbook](operations/03_databricks_runbook.md) | Databricks admins | Ordered SQL + notebook execution, UC, volumes |
| [Medallion objects catalog](operations/04_medallion_catalog.md) | Data eng / analysts | Every schema, table, view, metric explained |
| [Jobs & compute policy](operations/05_jobs_and_compute.md) | Platform / FinOps | Classic cluster only, DAB jobs, cost rules |
| [Governance & security](operations/06_governance_security.md) | Security / compliance | PII, masks, grants, audit checklist |
| [Agents & Genie](operations/07_agents_and_genie.md) | Analytics / AI ops | Genie space, agent tools, prompts |
| [Troubleshooting](operations/08_troubleshooting.md) | On-call | Common failures and fixes |
| [Glossary](operations/09_glossary.md) | Everyone | Terms used across the project |

## Supporting reference (already in repo)

| Document | Contents |
|---|---|
| [Architecture](architecture.md) | Concise architecture summary |
| [Data dictionary](data_dictionary.md) | Enrichment entity columns + PII notes |
| [PII inventory](../governance/pii_inventory.md) | Field classification + access matrix |
| [Access matrix](../governance/access_matrix.md) | Groups and service principals |
| [Tag taxonomy](../governance/tag_taxonomy.md) | UC tags |
| [Genie space](../agents/genie_space.md) | Allowed objects + sample questions |
| [Agent tool contracts](../agents/tool_contracts.md) | Tool I/O contracts |
| [System prompts](../agents/system_prompts.md) | Draft agent prompts |

## Suggested reading order (new operator)

1. Root README → [handbook](operations/00_handbook.md)
2. [End-to-end flow](operations/01_end_to_end_flow.md)
3. [Mock PI API](operations/02_mock_pi_api.md) (if running ingest)
4. [Databricks runbook](operations/03_databricks_runbook.md)
5. [Governance](operations/06_governance_security.md) before enabling Genie/agents
