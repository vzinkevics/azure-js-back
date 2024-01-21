import { DefaultAzureCredential } from "@azure/identity";
import { CosmosClient } from "@azure/cosmos";

const credential = new DefaultAzureCredential();

const client = new CosmosClient({
    endpoint: "https://cos-app-sand-ne-889.documents.azure.com:443/",
    aadCredentials: credential
});

const database = client.database('products-db');

export function getProductsContainer() {
    return database.container('products');
}

export function getStocksContainer() {
    return database.container('stocks');
}