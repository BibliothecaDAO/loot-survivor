import requests
import threading

def simulate_adventurer_getter():
    url = 'https://survivor-goerli-indexer.realms.world/graphql'

    # Example GraphQL query to get all adventurer information
    query = '''
        query {
            adventurers {
                actionsPerBlock
                beastHealth
                charisma
                chest
                createdTime
                dexterity
                foot
                gold
                hand
                head
                health
                id
                intelligence
                lastAction
                lastUpdatedTime
                luck
                name
                neck
                owner
                revealBlock
                ring
                startBlock
                statUpgrades
                strength
                timestamp
                vitality
                waist
                weapon
                wisdom
                xp
            }
        }
    '''

    response = requests.post(url, json={'query': query})
    print(f"{response.status_code}, {response.text}")

def main():
    query_threads = []

    for i in range(1):
        thread = threading.Thread(target=simulate_adventurer_getter)
        thread.start()
        query_threads.append(thread)

    for thread in query_threads:
        thread.join()

if __name__ == "__main__":
    main()
