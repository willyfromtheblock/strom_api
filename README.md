# PVPC_Server
[![Tests](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml/badge.svg)](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml)

A versatile **RESTful** program that aggregates and serves hourly price data for **Spanish electricity prices**.
The server will automatically fetch the price data for the next day, each day at 20:30 (Madrid time).
Garbage collection of old price data is included.

*Data Source: REData API*
### Examples
- Use as data source in home automation to make decisions based on current power price
- see [**openhab_example/pvpc_update.js**](/openhab_example/pvpc_update.js "**openhab_example/pvpc_update.js**")

### Prerequisites
- docker-compose

### Setup
- adapt environment in **docker-compose.yaml** accordingly or create a **docker-compose.override.yaml** file
- **do not change TZ**
- execute** ./deploy.sh **

PRs are welcome.
