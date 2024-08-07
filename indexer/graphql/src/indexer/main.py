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
@click.option("--mongo", default=None, help="Mongo url.")
@click.option("--port", default=None, help="Port number.")
@click.option(
    "--allowed-origin",
    multiple=True,
    help="Allowed origin for CORS. Can be specified multiple times.",
)
@click.option("--api-key", default=None, help="API key.")
@async_command
async def graphql(mongo, port, allowed_origin, api_key):
    """Start the GraphQL server."""
    if port is None:
        port = "8080"
    if mongo is None:
        mongo = "mongodb://mongo:mongo@localhost:27017"

    await run_graphql_api(
        mongo=mongo, port=port, allowed_origins=list(allowed_origin), api_key=api_key
    )
