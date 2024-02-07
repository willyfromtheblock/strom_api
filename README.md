# strom_api
[![Tests](https://github.com/willyfromtheblock/strom_api/actions/workflows/test.yaml/badge.svg)](https://github.com/willyfromtheblock/strom_api/actions/workflows/test.yaml)

A versatile **RESTful** program that aggregates and serves hourly data for **electricity prices**.

Just run this server, and it will do all the heavy lifting for you. 

# Suported Countries
### Spain (PVPC) 
- Data Source: REData API
- The server will automatically fetch the price data for the next day, each day at 20:30 (Madrid time).

# Examples
### Home Automation
- Use as data source in home automation to make decisions based on current power price
- see [**openhab_example/strom_update.js**](/openhab_example/strom_update.js "**openhab_example/strom_update.js**") (you'll need to create the referenced items before)

# REST endpoints
- General schema: endpoint/**timestampInSecondsSinceEpoch**/**zone**
- [Available price zones](https://strom-docs.coinerella.com/price_zones/PriceZone "Available price zones")
- GET `https://strom.coinerella.com/price/0/peninsular`
	```json
	{"time":"2023-04-05 14:00:00.000+0200","zone":"peninsular","price":0.11416,"price_rating_percent":64.18,"price_rating":"off_peak"}
	```
	
- GET `https://strom.coinerella.com/price-average/0/canarias`

	```json
	{"time":"2023-04-05 00:00:00.000","zone":"canarias","average_price":0.17787}
	```

- GET `https://strom.coinerella.com/price-daily/0/peninsular`

	```json
	[{
        "time": "2023-04-05 00:00:00.000+0200",
        "zone": "peninsular",
        "price": 0.10931,
        "price_rating_percent": 87.88,
        "price_rating": "off_peak"
    },
    {
        "time": "2023-04-05 01:00:00.000+0200",
        "zone": "peninsular",
        "price": 0.10634,
        "price_rating_percent": 85.5,
        "price_rating": "off_peak"
    }...]
	```

	0 is the timestamp in both cases. **0 will always return the current price in the local time for the requested zone.**
- [Detailed endpoint documentation](https://strom-docs.coinerella.com/rest_server/RESTServer/serve "Detailed endpoint documentation") 


# Why should I use this server over another API?
- Timeframes can be requested in seconds since epoch
- Price average for the given day is provided to classify each price in the daily context
- Easier to use REST endpoints
- Updates and cleans up data automatically (set and forget)
- Open source
- Great performance, thanks to **Dart** and **Alfred**

# Run your own
### Prerequisites
- docker-compose

### Configure
- adapt environment in **.env**, see **.env.example*
- **do not change TZ**
- **RATING_MARGIN** is a margin value in percent for price classification. Defaults to 10, meaning only prices 10% below the daily average will be considered off-peak. **Must be between 0 and 99.**

### Setup
- execute `./deploy.sh`
- Default port is 3001. **Congratulations**. You now have a running strom_api on this port. 
It can easily be reverse proxied if need be.

### Updating
- executing `./deploy.sh `will always rebuild the main branch of this repository and restart the container

## Development
### Run tests
- `dart test test/app_test_no_env.dart`
- `dart test test/app_test_with_env.dart`

### Simulate Github actions
- `act --secret-file my.secrets`

### Generate docs
- `dart doc .`