import { AzureFunction, Context, HttpRequest } from "@azure/functions"

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
    ];

    context.log('Products:', products);

    context.res = {
        // status: 200, /* Defaults to 200 */
        body: products
    };
};

export default httpTrigger;