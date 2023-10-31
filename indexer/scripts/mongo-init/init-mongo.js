db = db.getSiblingDB('mongo');

//
// add indexes
//
// items
db.items.createIndex({ "_cursor.to": 1, "adventurerId": 1, "item": 1});
db.items.createIndex({ "adventurerId": 1, "item": 1});
db.items.createIndex({ "_cursor.from": 1 });
db.items.createIndex({ "_cursor.to": 1 });

// adventurers
db.adventurers.createIndex({ "_cursor.to": 1, "adventurerId": 1 });
db.adventurers.createIndex({ "_cursor.from": 1 });
db.adventurers.createIndex({ "_cursor.to": 1 });
db.adventurers.createIndex({ "xp": -1 });

// battles
db.battles.createIndex({ "_cursor.to": 1, "adventurerId": 1 });
db.battles.createIndex({ "_cursor.from": 1 });
db.battles.createIndex({ "_cursor.to": 1 });

// beasts
db.beasts.createIndex({ "_cursor.to": 1, "adventurerId": 1 });
db.beasts.createIndex({ "_cursor.from": 1 });
db.beasts.createIndex({ "_cursor.to": 1 });

// discoveries
db.discoveries.createIndex({ "_cursor.to": 1, "adventurerId": 1 });
db.discoveries.createIndex({ "_cursor.from": 1 });
db.discoveries.createIndex({ "_cursor.to": 1 });

// scores
db.scores.createIndex({ "_cursor.to": 1, "adventurerId": 1 });
db.scores.createIndex({ "_cursor.from": 1 });
db.scores.createIndex({ "_cursor.to": 1 });
db.scores.createIndex({ "xp": -1});
db.scores.createIndex({ "rank": -1});
