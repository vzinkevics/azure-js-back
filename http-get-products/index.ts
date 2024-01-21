import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { AppConfigurationClient } from '@azure/app-configuration';
import { getProductsContainer, getStocksContainer } from "../cosmos-db/handler";

// // Create an App Config Client to interact with the service
// const connection_string = process.env.AZURE_APP_CONFIG_CONNECTION_STRING;
// const client = new AppConfigurationClient(connection_string);


type Product = {
    id: string;
    title: string;
    description: string;
    price: number;
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.', req);

    const products = (await getProductsContainer().items.readAll().fetchAll());
    context.log('Product list', products);

    const stocks = (await getStocksContainer().items.readAll().fetchAll());
    context.log('Stocks list', stocks);

    // // Retrieve a configuration key
    // const config = await client.getConfigurationSetting({ key: 'MY_AMAZING_CONFING' });
    // context.log(`Config MY_AMAZING_CONFING value: ${config}`);

    context.res = {
        body: products.resources?.map(product => ({
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price,
            count: stocks?.resources?.find(stock => stock.product_id === product.id).count ?? 0,
        } as Product))
    };
};

export default httpTrigger;