from contextlib import contextmanager
from typing import Optional, Generator
from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, sessionmaker

_engine: Optional[Engine] = None
_SessionLocal: Optional[type[Session]] = None

def _get_session_local():
    """
    Lazy-initialize and return the SQLAlchemy session factory.
    """
    global _SessionLocal # pylint: disable=global-statement

    if _SessionLocal is None:
        engine = get_engine()
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    return _SessionLocal

def get_engine() -> Engine:
    """
    Return the global SQLAlchemy engine binding.
    """
    from backend.config import config # pylint: disable=import-outside-toplevel
    global _engine # pylint: disable=global-statement

    if _engine is None:
        _engine = create_engine(config.postgres_uri)

    return _engine

def get_session() -> Generator[Session, None, None]:
    """
    Return a generator for an SQLAlchemy session.
    """
    session = _get_session_local()()
    try:
        yield session
    finally:
        session.close()

@contextmanager
def _yield_session() -> Generator[Session, None, None]:
    yield from get_session()

def get_session_as_context() -> Session:
    """
    Return a session as a context manager.
    """
    return _yield_session()
