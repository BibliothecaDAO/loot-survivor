FROM python:3.9-buster

WORKDIR /app

COPY src .
COPY poetry.lock .
COPY pyproject.toml .
COPY simple_server.py .

RUN python3 -m pip install poetry
RUN python3 -m pip install pycryptodome
RUN poetry config virtualenvs.create false
RUN poetry install

ENTRYPOINT ["python3", "simple_server.py"]