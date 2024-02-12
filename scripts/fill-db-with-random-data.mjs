import { faker } from "@faker-js/faker";
import { v4 as uuidv4 } from "uuid";
import { CosmosClient } from "@azure/cosmos";

const client = new CosmosClient({
    endpoint: "https://cos-app-sand-ne-889.documents.azure.com:443/",
    key: "" // enter your key
});

const database = client.database('products-db');

export function getProductsContainer() {
    return database.container('products');
}

export function getStocksContainer() {
    return database.container('stocks');
}

async function main() {
    for (let i = 0; i < 10; i++) {
        const id = uuidv4();
        const title = faker.commerce.productName();
        const description = faker.commerce.productDescription();
        const price = faker.commerce.price();
        const count = faker.number({ length: { min: 100, max: 100000 } });

        const productItem = { id, title, description, price };
        const stockItem = { id, product_id: id, count };

        const { resource: createdProduct } = await getProductsContainer().items.create(
            productItem
        );
        console.log(`Created product: ${createdProduct.id}`);

        const { resource: createdStock } = await getStocksContainer().items.create(
            stockItem
        );
        console.log(`Created stock: ${createdStock.product_id}`);
    }
}

main().catch((error) => {
    console.error(error);
});