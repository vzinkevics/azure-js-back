import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { AppConfigurationClient } from '@azure/app-configuration';

// Create an App Config Client to interact with the service
const connection_string = process.env.AZURE_APP_CONFIG_CONNECTION_STRING;
const client = new AppConfigurationClient(connection_string);


type Product = {
    id: string;
    title: string;
    description: string;
    price: number;
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');

    const products: Product[] = [
        { id: '101', title: 'Product101', description: 'good product', price: 100 },
        { id: '102', title: 'Product102', description: 'bad product', price: 50 },
        { id: '103', title: 'Product103', description: 'norm product', price: 530 },
        { id: '104', title: 'Product104', description: 'better product', price: 535 },
    ];

    context.log('Products:', products);

    // Retrieve a configuration key
    const config = await client.getConfigurationSetting({ key: 'MY_AMAZING_CONFING' });
    context.log(`Config MY_AMAZING_CONFING value: ${config}`);

    context.res = {
        // status: 200, /* Defaults to 200 */
        body: products
    };
};

export default httpTrigger;