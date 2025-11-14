import traceback
from typing import Callable
from logging import getLogger
from contextlib import asynccontextmanager
from sqlalchemy.orm import Session
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from .database import get_session_as_context

logger = getLogger(__name__)

class APIJobs:
    jobs: dict[str, Callable]
    scheduler: AsyncIOScheduler

    def __init__(self):
        self.jobs = {}
        self.scheduler = AsyncIOScheduler()

    def get_lifespan(self):
        @asynccontextmanager
        async def lifespan(_app: FastAPI):
            """
            Lifespan for FastAPI integration.
            """
            self.scheduler.start()
            yield
            self.scheduler.shutdown()

        return lifespan

    def job(self, interval_seconds: int = 5):
        def decorator(func: Callable[[Session], None]):
            def wrapped(_: None = None, **kwargs):
                try:
                    with get_session_as_context() as session:
                        func(session, **kwargs)
                except Exception as err: # pylint: disable=broad-except
                    logger.error(
                        "%s: %s%s",
                        func.__name__, str(err),
                        "".join(traceback.format_tb(err.__traceback__))
                    )

            self.scheduler.add_job(
                wrapped, "interval",
                name=func.__name__,
                seconds=interval_seconds,
                max_instances=1
            )

            self.jobs[func.__name__] = func

            return wrapped
        return decorator

# HTTP-mapped error types.
class Invalid(Exception):
    pass

class Unauthorized(Exception):
    pass

def _invalid_handler(_req: Request, exc: Invalid):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={ "error": str(exc) }
    )

def _unauthorized_handler(_req: Request, exc: Unauthorized):
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={ "error": str(exc) }
    )

def _unprocessable_handler(_req: Request, _exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={ "error": "unprocessable" }
    )

def _not_found_handler(_req: Request, _exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={ "error": "not_found" }
    )

def _internal_error_handler(_req: Request, _exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={ "error": "internal_err" }
    )

def _health_check():
    return { "status": "healthy" }

def create_api(root_path: str) -> (FastAPI, APIJobs):
    """
    Create a FastAPI app with common configuration including error handlers and a
    health check endpoint.
    """
    from backend.config import config # pylint: disable=import-outside-toplevel

    jobs = APIJobs()

    api = FastAPI(root_path=root_path, lifespan=jobs.get_lifespan())

    service_origin = config.service_origin

    api.add_middleware(
        CORSMiddleware,
        allow_origins=[service_origin] if service_origin else [],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    )
    api.exception_handler(Invalid)(_invalid_handler)
    api.exception_handler(Unauthorized)(_unauthorized_handler)
    api.exception_handler(422)(_unprocessable_handler)
    api.exception_handler(404)(_not_found_handler)
    api.exception_handler(500)(_internal_error_handler)
    api.get("/health")(_health_check)

    return api, jobs
