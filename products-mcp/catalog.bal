// Lookups over the built-in catalog in data.bal.

// Products whose name, description or category contains query, optionally in one category, best rated first.
isolated function searchCatalog(string query, string category) returns ProductSummary[] {
    string q = query.trim().toLowerAscii();
    string c = category.trim().toLowerAscii();
    return from Product p in products
        where (c == "" || p.category == c)
            && (q == "" || p.name.toLowerAscii().includes(q)
                || p.description.toLowerAscii().includes(q)
                || p.category.includes(q))
        order by p.rating descending
        select {sku: p.sku, name: p.name, category: p.category, price: p.price, currency: p.currency};
}

isolated function stockFor(string sku) returns Stock? {
    map<int>? levels = stockLevels[sku];
    if levels is () {
        return ();
    }
    SizeStock[] sizes = [];
    boolean inStock = false;
    foreach [string, int] [size, quantity] in levels.entries() {
        sizes.push({size, quantity});
        if quantity > 0 {
            inStock = true;
        }
    }
    return {sku, inStock, sizes};
}
