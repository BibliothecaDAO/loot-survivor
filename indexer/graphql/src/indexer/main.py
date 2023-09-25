"""Apibara indexer entrypoint."""

import asyncio
from functools import wraps

import click

from apibara.protocol import StreamAddress

from indexer.graphql import run_graphql_api


def async_command(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        return asyncio.run(f(*args, **kwargs))

    return wrapper


@click.group()
def cli():
    pass


@cli.command()
@click.option("--mongo_goerli", default=None, help="Mongo url for goerli.")
@click.option("--mongo_mainnet", default=None, help="Mongo url for mainnet.")
@click.option("--port", default=None, help="Port number.")
@async_command
async def graphql(mongo_goerli, mongo_mainnet, port):
    """Start the GraphQL server."""
    if port is None:
        port = "8080"
    if mongo_goerli is None:
        mongo_goerli = "mongodb://mongo:mongo@localhost:27017"
    if mongo_mainnet is None:
        mongo_mainnet = "mongodb://apibara:apibara@localhost:27018"

    await run_graphql_api(
        mongo_goerli=mongo_goerli, mongo_mainnet=mongo_mainnet, port=port
    )
