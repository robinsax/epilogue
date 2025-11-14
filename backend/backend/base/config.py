import os
from typing import TypeVar

from .model import Model

T = TypeVar("T", bound=Model)
class ConfigMixin:

    @classmethod
    def load(cls: type[T]) -> T:
        values = {}
        for key, field in cls.model_fields.items():
            raw_value = os.getenv(key)
            if raw_value is None:
                if field.is_required():
                    raise ValueError(f"Missing environment variable: {key}")
                else:
                    continue

            values[key] = raw_value

        return cls(**values)
