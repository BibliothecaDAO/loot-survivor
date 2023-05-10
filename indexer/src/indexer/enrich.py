import requests
from typing import List, Dict, Optional
from dataclasses import dataclass

@dataclass
class EventBase:
    event_name: str
    event_type: str
    world_id: int
    description: str
    start_date: str
    end_date: str


@dataclass
class EventInput:
    entity_id: Optional[int]
    entity_name: str
    entity_type: str
    world_id: int
    event_name: str
    event_type: str
    description: str
    start_date: str
    end_date: str
    role: str


class EventsAPI:
    def __init__(self, base_url: str, world_id: int):
        self.base_url = base_url
        self.headers = {}
        self.world_id = world_id

    def get_event_list(self) -> List[EventBase]:
        response = requests.get(f"{self.base_url}/events/all", headers=self.headers)
        response.raise_for_status()
        return [EventBase(**event) for event in response.json()]

    def get_events_by_world(self) -> List[EventBase]:
        response = requests.get(f"{self.base_url}/events/all/{self.world_id}", headers=self.headers)
        response.raise_for_status()
        return [EventBase(**event) for event in response.json()]

    def get_events_by_entity(self, entity_id: int) -> List[EventBase]:
        response = requests.get(f"{self.base_url}/events/entity/{entity_id}", headers=self.headers)
        response.raise_for_status()
        return [EventBase(**event) for event in response.json()]

    async def create_entity_event(self, event_input: EventInput) -> Dict[str, int]:
        response = requests.post(f"{self.base_url}/events/entity", headers=self.headers, json=event_input.__dict__)
        response.raise_for_status()
        return response.json()


# # Usage example:

# events_api = EventsAPI("<API_BASE_URL>", "<YOUR_TOKEN>")
# events = events_api.get_event_list()
# print(events)