import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { getProductsContainer, getStocksContainer } from "../cosmos-db/handler";
import { v4 as uuidv4 } from 'uuid';

type Product = {
    id: string;
    title: string;
    description: string;
    price: number;
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.', req);

    if (!req.body.title) {
        context.res = {
            status: 400,
            body: {
                error: 'Product title should be defined',
            }
        };
        return;
    }

    await getProductsContainer().items.create({
        ...req.body,
        id: uuidv4()
    });

    context.res = {
        status: 200,
        body: {}
    };
};

export default httpTrigger;