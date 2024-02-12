import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { getProductsContainer, getStocksContainer } from "../cosmos-db/handler";

type Product = {
    id: string;
    title: string;
    description: string;
    price: number;
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.', req);

    const products = await getProductsContainer().items
        .query({
            query: "SELECT * FROM c WHERE c.id = @id",
            parameters: [{ name: "@id", value: req.params.productId }]
        })
        .fetchAll();

    const product = products.resources[0];
    context.log('Products:', product);

    const stocks = await getStocksContainer().items
        .query({
            query: "SELECT * FROM c WHERE c.product_id = @id",
            parameters: [{ name: "@id", value: req.params.productId }]
        })
        .fetchAll();

    const stock = stocks.resources[0];
    context.log('Stocks list', stock);

    context.res = {
        // status: 200, /* Defaults to 200 */
        body: {
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price,
            count: stock.count
        } as Product
    };
};

export default httpTrigger;