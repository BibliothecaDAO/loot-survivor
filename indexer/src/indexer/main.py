"""Apibara indexer entrypoint."""

import asyncio
from functools import wraps

import click

from apibara.protocol import StreamAddress

from indexer.indexer import run_indexer
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
@click.option("--server-url", default=None, help="Apibara stream url.")
@click.option("--mongo-url", default=None, help="MongoDB url.")
@click.option("--restart", is_flag=True, help="Restart indexing from the beginning.")
@click.option("--network", default=None, help="Network id.")
@click.option("--adventurer", is_flag=None, help="Adventurer contract address.")
@click.option("--beast", is_flag=None, help="Beast contract address.")
@click.option("--loot", is_flag=None, help="Loot contract address.")
@click.option("--start_block", is_flag=None, help="Indexer starting block.")
@async_command
async def start(
    server_url, mongo_url, restart, network, adventurer, beast, loot, start_block
):
    """Start the Apibara indexer."""
    if server_url is None:
        server_url = StreamAddress.StarkNet.Goerli

    if mongo_url is None:
        mongo_url = "mongodb://apibara:apibara@localhost:27017"

    await run_indexer(
        restart=restart,
        server_url=server_url,
        mongo_url=mongo_url,
        network=network,
        adventurer=adventurer,
        beast=beast,
        loot=loot,
        start_block=start_block,
    )


@cli.command()
@click.option("--mongo_goerli", default=None, help="Mongo url for goerli.")
@click.option("--mongo_devnet", default=None, help="Mongo url for devnet.")
@click.option("--port", default=None, help="Port number.")
@async_command
async def graphql(mongo_goerli, mongo_devnet, port):
    """Start the GraphQL server."""
    if port is None:
        port = "8080"

    await run_graphql_api(
        mongo_goerli=mongo_goerli, mongo_devnet=mongo_devnet, port=port
    )
