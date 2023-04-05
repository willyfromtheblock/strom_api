# PVPC_Server
[![Tests](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml/badge.svg)](https://github.com/willyfromtheblock/dart_scripthash_generator/actions/workflows/dart.yml)

A versatile **RESTful** program that aggregates and serves hourly data for **Spanish electricity prices** from the Precio voluntario para el pequeño consumidor (**PVPC**).

The server will automatically fetch the price data for the next day, each day at 20:30 (Madrid time).
Just run this server, and it will do all the heavy lifting for you. 

*Data Source: REData API*
## Examples
### Home Automation
- Use as data source in home automation to make decisions based on current power price
- see [**openhab_example/pvpc_update.js**](/openhab_example/pvpc_update.js "**openhab_example/pvpc_update.js**") (you'll need to create the referenced items before)

### REST endpoints
- General schema: endpoint/**timestampInSecondsSinceEpoch**/**zone**
- [Available price zones](https://pvpc-docs.coinerella.com/price_zones/PriceZone "Available price zones")
- GET `https://pvpc.coinerella.com/price/0/peninsular`
	```json
	{"time":"2023-04-05 14:00:00.000+0200","zone":"peninsular","price":0.11416,"price_rating_percent":64.18,"price_rating":"off_peak"}
	```
	
- GET `https://pvpc.coinerella.com/price-average/0/canarias`

	```json
	{"time":"2023-04-05 00:00:00.000","zone":"canarias","average_price":0.17787}
	```

	0 is the timestamp in both cases. **0 will always return the current price in the local time for the requested zone.**
- [Detailed endpoint documentation](https://pvpc-docs.coinerella.com/rest_server/RESTServer/serve "Detailed endpoint documentation") 


## Why should I use this server over the REData API?
- Timeframes can be requested in seconds since epoch
- Price average for the given day is provided to classify each price in the daily context
- Easier to use REST endpoints
- Updates and cleans up data automatically (set and forget)
- Open source
- Great performance, thanks to **Dart** and **Alfred**

## Run your own
### Prerequisites
- docker-compose

### Configure
- adapt environment in **docker-compose.yaml** accordingly or create a **docker-compose.override.yaml** file
- **do not change TZ**
- **RATING_MARGIN** is a margin value in percent for price classification. Defaults to 10, meaning only prices 10% below the daily average will be considered off-peak. **Must be between 0 and 99.**

### Setup
- execute `./deploy.sh`
- Default port is 3001. **Congratulations**. You now have a running PVPC_Server on this port. 
It can easily be reverse proxied if need be.

### Updating
- executing `./deploy.sh `will always rebuild the main branch of this repository and restart the container

## Development
### Run tests
- `dart test test/app_test_no_env.dart`
- `dart test test/app_test_with_env.dart`

### Generate docs
- `dart doc .`