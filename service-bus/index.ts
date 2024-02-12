import { v4 as uuidv4 } from "uuid";
import { AzureFunction, Context } from "@azure/functions";

import { getProductsContainer, getStocksContainer } from "../cosmos-db/handler";

const productCreatedHandler: AzureFunction = async function (context: Context, message: any) {
    try {
        context.log("Event handler invocation start");
        const id = uuidv4();

        await getProductsContainer().items.create({
            id: uuidv4(),
            title: message.title,
            description: message.description,
            price: Number(message.price),
        });

        await getStocksContainer().items.create({
            product_id: id,
            count: Number(message.count),
        });

        context.log("Event handled successfully");
    } catch (error) {
        context.log.error("Cannot handle event", error);
        throw error;
    }
};

export default productCreatedHandler;