import ballerina/lang.regexp;
import ballerina/mcp;

configurable int port = 9090;

final regexp:RegExp skuPattern = re `[A-Z0-9-]{3,32}`;
final regexp:RegExp topicPattern = re `[a-z-]{1,32}`;

listener mcp:StreamableHttpListener productsListener = check new (port);

// Stateless, so any replica can answer any request. Read-only: four tools that look things up in the
// built-in catalog (data.bal), so the server needs no upstream API, key or Resource.
@mcp:StreamableHttpServiceConfig {
    info: {
        name: "Products MCP Server",
        version: "0.1.0"
    },
    sessionMode: mcp:STATELESS,
    options: {
        instructions: "Product catalog, stock and store policies for Summit Outdoor."
    }
}
service mcp:StreamableHttpService /mcp on productsListener {

    # Search the product catalog by name, description or category.
    #
    # + query - Words to look for, such as "rain jacket" or "tent"
    # + category - Optional category: jackets, tents, sleeping-bags, packs, footwear or cooking
    # + return - Matching products with SKU and price, best rated first
    remote function searchProducts(string query, string? category = ()) returns ProductSummary[]|error {
        string q = query.trim();
        if q.length() > 100 {
            return error("Keep the search under 100 characters");
        }
        return searchCatalog(q, category ?: "");
    }

    # Get the full details of one product: description, features, sizes, price and rating.
    #
    # + sku - The product SKU such as "JKT-TRAIL-01", from searchProducts
    # + return - The product, or an error if no product has that SKU
    remote function getProduct(string sku) returns Product|error {
        string id = check normalizeSku(sku);
        Product? product = products[id];
        return product ?: error(string `No product with SKU ${id}`);
    }

    # Check how many units are in stock for each size of a product.
    #
    # + sku - The product SKU such as "JKT-TRAIL-01", from searchProducts
    # + return - Units on hand per size, and whether any size is in stock
    remote function checkStock(string sku) returns Stock|error {
        string id = check normalizeSku(sku);
        Stock? stock = stockFor(id);
        return stock ?: error(string `No product with SKU ${id}`);
    }

    # Read a store policy.
    #
    # + topic - One of: returns, shipping, warranty, price-match
    # + return - The policy summary and its details
    remote function getPolicy(string topic) returns Policy|error {
        string t = topic.trim().toLowerAscii();
        string unknown = "Unknown policy. Topics are: returns, shipping, warranty, price-match";
        if !topicPattern.isFullMatch(t) {
            return error(unknown);
        }
        Policy? policy = policies[t];
        return policy ?: error(unknown);
    }
}

// Accepts "jkt-trail-01" or " JKT-TRAIL-01 " and rejects anything that isn't a SKU.
isolated function normalizeSku(string sku) returns string|error {
    string id = sku.trim().toUpperAscii();
    if !skuPattern.isFullMatch(id) {
        return error("SKUs look like JKT-TRAIL-01. Use searchProducts to find one");
    }
    return id;
}
