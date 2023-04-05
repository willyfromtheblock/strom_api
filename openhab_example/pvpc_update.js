const response = actions.HTTP.sendHttpGetRequest('https://pvpc.coinerella.com/price/0/peninsular');
const parsed = JSON.parse(response);

const currentPriceItem = items.getItem('PVPCServer_current_price');
currentPriceItem.postUpdate(parseFloat(parsed['price']));

const currentPriceRating = items.getItem('PVPCServer_Currentpricerating');
currentPriceRating.postUpdate(parsed['price_rating']);

const currentPriceTimeStamp = items.getItem('PVPCServer_Timestampforcurrentprice');
currentPriceTimeStamp.postUpdate(parsed['time']);