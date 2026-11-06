# Product Help Agent

A shopping assistant for Summit Outdoor, a fictional outdoor gear store. Shoppers ask it things like
"Is the Trailblazer jacket in stock in size M?" or "What's your return policy?", and it answers from the
store's catalog through MCP tools.

The catalog is built into the MCP server, so there is no API to host, no key to manage and no Resource to
register: deploy two components and try it.

```
Try It ──▶ Product Help Agent ──▶ MCP gateway ──▶ Products MCP server
           (Agent Manager)       (API Platform)   (Integrator, built-in catalog)
```

| Component | Runs on | Path | Language |
|---|---|---|---|
| Products MCP server | Integrator, `mcp-server` | `products-mcp/` | Ballerina 2201.13.1 |
| Product Help Agent | Agent Manager, platform-hosted chat agent | `agent/` | Python 3.11 |

The catalog, stock and policies are fictional mock data, and everything is read-only.

## Deploy on WSO2 Cloud

### 1. Deploy the MCP server

In the Integration Platform, create an integration from this repository: type `mcp-server`, path
`products-mcp`, WSO2 Integrator runtime. It needs no environment variables. Deploy it to Development.

Then make the integration's endpoint public, so it's published on the MCP gateway. The MCP URL is that
gateway URL plus `/mcp`.

### 2. Deploy the agent

In Agent Manager, create a platform-hosted Python agent from this repository: app path `/agent`,
Python 3.11, default chat interface. Then:

1. Bind an Anthropic LLM provider, with the env var names `LLM_PROVIDER_URL` and `LLM_PROVIDER_KEY`.
2. Set `PRODUCTS_MCP_URL` to the MCP URL from step 1, and `MCP_API_KEY` to the MCP gateway's API key,
   as a secret.
3. Deploy, then open **Try It**.

## Products MCP server

Port `9090`, path `/mcp`, stateless. Four read-only tools over the built-in catalog in
[`products-mcp/data.bal`](products-mcp/data.bal):

| Tool | What it does |
|---|---|
| `searchProducts` | Search by words and optional category |
| `getProduct` | Full product details |
| `checkStock` | Units per size |
| `getPolicy` | One store policy: returns, shipping, warranty or price-match |

It has no environment variables. To change what the store sells, edit `data.bal` and redeploy.

## Product Help Agent

Serves `POST /chat` on port `8000` (`{"message", "session_id"}` in, `{"response", "session_id"}` out) and
`GET /health`. Agent Manager starts it with `python main.py`.

| Env var | Required | Purpose |
|---|---|---|
| `PRODUCTS_MCP_URL` | Yes | The MCP gateway URL plus `/mcp` |
| `MCP_API_KEY` | When the MCP gateway checks keys | Sent as `X-API-Key`. Store it as a secret |
| `LLM_PROVIDER_URL`, `LLM_PROVIDER_KEY` | When `USE_LLM_PROVIDER=true` | Injected by Agent Manager from the bound Anthropic provider |
| `USE_LLM_PROVIDER` | No, default `true` | `false` for a local run straight against Anthropic |
| `ANTHROPIC_API_KEY` | When `USE_LLM_PROVIDER=false` | Local runs only |
| `MODEL` | No, default `claude-opus-5-5` | Claude model |
| `MAX_TOKENS` | No, default `16000` | Cap on each reply |
| `STORE_NAME` | No, default `Summit Outdoor` | Name used in the instructions |

The agent sends the provider key in `API-Key`, which the Agent Manager LLM gateway reads, and calls
`<LLM_PROVIDER_URL>/v1/messages` (a trailing `/v1` on the URL is dropped first).

## Run locally

```bash
cd products-mcp && bal run
```

```bash
cd agent
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export PRODUCTS_MCP_URL=http://localhost:9090/mcp USE_LLM_PROVIDER=false ANTHROPIC_API_KEY=<your-key>
python main.py
```

```bash
curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" \
  -d '{"message": "Is the Trailblazer jacket in stock in size M?", "session_id": "demo"}'
```
