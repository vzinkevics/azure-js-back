import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { getStocksContainer } from "../cosmos-db/handler";

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.', req);

    const querySpec = {
        query: `SELECT VALUE SUM(c.count) FROM c`,
    };
    const { resources } = await getStocksContainer().items
        .query(querySpec)
        .fetchAll();

    console.log(resources);

    context.res = {
        status: 200,
        headers: {
            "content-type": "application/json",
        },
        body: resources[0],
    };
};

export default httpTrigger;