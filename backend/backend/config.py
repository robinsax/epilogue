from .base import Model, ConfigMixin

class Config(Model, ConfigMixin):
    postgres_uri: str
    service_origin: str | None = None
    service_port: int = 8000

config = Config.load()
