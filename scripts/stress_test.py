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
        query get_adventurer_by_xp {
            adventurers(orderBy: { xp: { desc: true } }, limit: 10000000) {
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

    # Generate a list of adventurer IDs from 1 to 10000
    adventurer_ids = list(range(1, 10001))
    adventurer_ids_str = ", ".join(map(str, adventurer_ids))

    score_query = f"""
        query get_top_scores {{
            scores(where: {{ adventurerId: {{ In: [{adventurer_ids_str}] }} }}, limit: 10000000) {{
                adventurerId
                timestamp
                totalPayout
            }}
        }}
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
