# Changelog

All notable changes to this project will be documented in this file.

## [0.0.1] - 2025-06-02

The first public version.

### Added

- Support for **clickhouse** basic operations.
- Support for **postgresql** basic operations.
- Support for **rabbitmq** basic operations.
- Support for **redis** basic operations.
- Support for **rustup** and **cargo** basic operations.
- Support for some **cargo crates** basic operations.
- Support for some **docker** basic operations.
- Support for some **git** basic operations.
- Support for some **tmux** basic operations.

## [0.0.2] - 2025-08-15

Hierarchy of vars and shell auto completion for commands.

### Added

- **Shell auto completion** for commands.
- **Hierarchy** of files containing variables.
- Using **process substitution** for taking vars from other `.sh` files.
- **Sourcing of vars** in commands.
- Using `set -eu` in commands.
- Using **subshells** `foo() { ( ... ) }` in commands for **isolation**.
