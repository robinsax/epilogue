# epilogue

Very much so under construction as an experiment in both multiplayer infrastructure and Godot.

The game is about collecting loot. It's comprised of a persistent per-user "home", and separate extration-based multiplayer matches.

"Home" gameplay occurs in a local session and is persisted to a REST API. Multiplayer matches occur against a dedicated server. The matchmaker dynamically allocates and destroys these as needed. The source of truth for all game state, including the "home" world, is persisted in a database.

## Architecture

* Client API service - API capacity for game clients would be a scale constraint in this setup. This service exists for horizontal scaling.
* Hub service - Internal service for all point of control operations. Would need to be broken out more at scale; currently handles matchmaking, match server allocation, and match server service provision.
* Match service - Dedicated server container(s) dynamically allocated by hub service. Interfaces with hub service to orchestrate initial game state, world generation, and match result commits.

## Stack

* MongoDB
* Godot / GDScript
* Python (for the backend prototype)
* Docker

Dev tools:
* Mongo Express

Expected future:
* Rust (for an actual backend implementation)
* Terraform
* GCP
