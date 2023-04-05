# PVPC_Server
[![Tests](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml/badge.svg)](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml)

A versatile **RESTful** program that aggregates and serves hourly data for **Spanish electricity prices** from the Precio voluntario para el pequeño consumidor (**PVPC**).

The server will automatically fetch the price data for the next day, each day at 20:30 (Madrid time).
Just run this server, and it will do all the heavy lifting for you. 

*Data Source: REData API*
### Examples
- Use as data source in home automation to make decisions based on current power price
- see [**openhab_example/pvpc_update.js**](/openhab_example/pvpc_update.js "**openhab_example/pvpc_update.js**")

### Why should I use this server over the REData API?
- Timeframes can be requested in seconds since epoch
- Price average for the given day is provided to classify each price in the daily context
- Easier to use REST endpoints
- Updates and cleans up data automatically - set and forget
- Open source
- Great performance, thanks to **Dart** and **Alfred**

### Prerequisites
- docker-compose

### Configure
- adapt environment in **docker-compose.yaml** accordingly or create a **docker-compose.override.yaml** file
- **do not change TZ**
- **RATING_MARGIN** is a margin value in percent for price classification. Defaults to 10, meaning only prices 10% below the daily average will be considered off-peak.  

### Setup
- execute **./deploy.sh**

### Updating
- execute **./deploy.sh** will always rebuild the main branch of this repository