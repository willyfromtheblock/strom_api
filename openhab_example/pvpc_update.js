const response = actions.HTTP.sendHttpGetRequest('https://pvpc-hourly-spanish-energy-prices-api.p.rapidapi.com/price/0/peninsular', {
    'X-RapidAPI-Key': 'your-rapid-api-key',
    'X-RapidAPI-Host': 'your-rapid-api-host'
}, 10000);
const parsed = JSON.parse(response);

const currentPriceItem = items.getItem('PVPCServer_current_price');
currentPriceItem.postUpdate(parseFloat(parsed['price']));

const currentPriceRating = items.getItem('PVPCServer_Currentpricerating');
currentPriceRating.postUpdate(parsed['price_rating']);

const currentPriceTimeStamp = items.getItem('PVPCServer_Timestampforcurrentprice');
currentPriceTimeStamp.postUpdate(parsed['time']);