# Loot Survivor Indexer

Getting started:

 - Install the Apibara CLI ([see this page for instructions](https://www.apibara.com/docs/getting-started))
 - Install the `sink-mongo` and `sink-console` plugins.
   * `apibara plugins install sink-mongo`
   * `apibara plugins install sink-console`
 - Verify they are installed with `apibara plugins list`


## Organization

We divide indexers based on which collection they are going to update:

 - adventurers
 - bags
 - beasts
 - battles
 - discoveries
 - items
 - scores


## Adding an indexer

Indexers can work in two modes:

 - default: append the values returned by the transform function to the table. This is useful if you're storing a list of things.
 - entities: update the state of an item. This is called [entity mode](https://www.apibara.com/docs/integrations/mongo#entity-storage)
 and it basically leverages MongoDB update operations.


## Running

My advice is to run using `sinkType: console` while debugging since it simply prints values to console.
Change to `sinkType: mongo` once you're ready to store data in Mongo.

Run an indexer with:

```
apibara run --allow-env=env src/<indexer>.ts -A dna_XXX
```

If storing data in MongoDB:

```
apibara run --allow-env=env src/<indexer>.ts -A dna_XXX --connection-string "mongodb://..."
```

or set the `MONGO_CONNECTION_STRING` environment variable.


## Indexer state persistence

To persist state between runs, add the following options:

```
--persist-to-fs=.apibara --sink-id=<my-indexer>
```

Then you will find the indexer state in the `.apibara` folder.


## Editor Setup

[See guide linked here](https://www.apibara.com/docs/getting-started#setting-up-your-environment)
