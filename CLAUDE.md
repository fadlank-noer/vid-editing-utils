## Rules (Required)
- Always fix the user's comments to proper English when writing code or docs.
- Keep `README.md` up to date — update it whenever a new feature is added.
- When the user adds a feature instruction under a `feature -> <name>` heading in this file, read and implement it directly.
- Follow conventional commit messages (e.g., `feat:`, `fix:`, `refactor:`).

## Tech Stack

### Backend — Prabogo
- **Framework:** [Prabogo](https://prabogo.com/) — Modern Go framework with hexagonal architecture, interactive commands, and built-in AI assistance.
- **Language:** Go
- **Architecture:** Hexagonal / Clean Architecture
- **Setup:** `go install github.com/prabogo/prabogo-install@latest` then `prabogo-install <project-name>`

### Frontend — FlightPHP
- **Framework:** [FlightPHP v3](https://docs.flightphp.com/en/v3/) — Fast, simple, extensible PHP micro-framework with zero dependencies.
- **Language:** PHP 7.4+
- **Install:** `composer require flightphp/core`
- **Skeleton:** `composer create-project flightphp/skeleton my-project/`

### Build System — Bazel Monorepo
- **Tool:** [Bazel](https://bazel.build/) — Scalable build and test system for multi-language, multi-platform codebases.
- **Structure:** Monorepo — all services and packages in a single repository.
- **Features:** Incremental builds, advanced caching, parallel execution, multi-language support (Go, PHP, etc.).