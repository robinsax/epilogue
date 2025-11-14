import os
from logging.config import fileConfig

from alembic import context

from backend.base import Base, get_engine

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline() -> None:
    uri = os.environ.get("POSTGRES_URI")
    if not uri:
        raise ValueError("No POSTGRES_URI")

    context.configure(
        url=uri,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={ "paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """
    Run migrations in "online" mode.

    In this scenario we need to create an Engine and associate a connection with the
    context.
    """
    factory = get_engine()

    with factory.connect() as conn:
        context.configure(connection=conn, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
