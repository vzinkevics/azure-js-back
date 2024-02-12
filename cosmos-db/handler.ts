import { DefaultAzureCredential } from "@azure/identity";
import { CosmosClient } from "@azure/cosmos";

const credential = new DefaultAzureCredential();

// const client = new CosmosClient({
//     endpoint: "https://cos-app-sand-ne-889.documents.azure.com:443/",
//     aadCredentials: credential
// });

const client = new CosmosClient({
    endpoint: "https://cos-app-sand-ne-889.documents.azure.com:443/",
    key: "NXt3O68gZBoWx94mpVNvHggK0aYARuLjmJzPuUbg8cykRqUI0tU00IAM0pwZNUOZxvlqV6q6DB8fACDbj15X4g=="
});

const database = client.database('products-db');

export function getProductsContainer() {
    return database.container('products');
}

export function getStocksContainer() {
    return database.container('stocks');
}