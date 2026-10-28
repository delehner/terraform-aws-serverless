# CLAUDE.md

Public Terraform module `terraform-aws-serverless`, published to the HCP Terraform private registry of the `denilson-lehner-portfolio` organization. Its variables and outputs are a public contract: follow semantic versioning (ADR 0007 of the handbook), update `README.md` and `CHANGELOG.md` in every change, and never commit account IDs, real ARNs, private domains or e-mails.

## Shared context

Common rules for all of Denilson's personal repositories live in the [`handbook`](https://github.com/delehner/handbook/blob/main/AGENTS.md), loaded through the root `CLAUDE.md` of the [`workspace`](https://github.com/delehner/workspace) (clone it and run `./ws sync`). Specialist agents and the `council` and `orchestrate` skills come from the `delehner-core` plugin, enabled in `.claude/settings.json`. Rules in this file win when they are more specific.

## Specialist

Changes here are delegated to the `terraform-module-developer` agent (`delehner-core` plugin).

## Verification

```bash
terraform fmt -recursive -check && terraform init -backend=false && terraform validate
```
