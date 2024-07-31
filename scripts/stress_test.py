import requests
import threading
import time


def simulate_adventurer_getter():
    url = "http://localhost:8080/graphql"

    # Example GraphQL query to get all adventurer information
    # query = '''
    #     query {
    #         adventurers {
    #             actionsPerBlock
    #             beastHealth
    #             charisma
    #             chest
    #             createdTime
    #             dexterity
    #             foot
    #             gold
    #             hand
    #             head
    #             health
    #             id
    #             intelligence
    #             lastAction
    #             lastUpdatedTime
    #             luck
    #             name
    #             neck
    #             owner
    #             revealBlock
    #             ring
    #             startBlock
    #             statUpgrades
    #             strength
    #             timestamp
    #             vitality
    #             waist
    #             weapon
    #             wisdom
    #             xp
    #         }
    #     }
    # '''

    basic_query = """
        query get_adventurer {
            adventurers {
                id
                owner
                entropy
                name
                health
                strength
                dexterity
                vitality
                intelligence
                wisdom
                charisma
                luck
                xp
                weapon
                chest
                head
                waist
                foot
                hand
                neck
                ring
                beastHealth
                statUpgrades
                startEntropy
                revealBlock
                gold
                createdTime
                lastUpdatedTime
                timestamp
            }
        }
    """

    leaderboard_query = """
        query get_dead_adventurers_by_xp_paginated {
            adventurers(
            where: { health: { eq: 0 } }
            limit: 10
            skip: 0
            orderBy: { xp: { desc: true } }
            ) {
                id
            }
        }
    """

    requests.post(url, json={"query": leaderboard_query})


def main():
    query_threads = []
    start_time = time.time()  # Record the start time

    for i in range(1000):
        thread = threading.Thread(target=simulate_adventurer_getter)
        thread.start()
        query_threads.append(thread)

    for thread in query_threads:
        thread.join()

    end_time = time.time()  # Record the end time
    print(f"Time taken: {end_time - start_time} seconds")  # Print the time taken


if __name__ == "__main__":
    main()
