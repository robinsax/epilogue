import uuid
from enum import Enum
from datetime import datetime, timezone
from typing import Union, Any, get_origin, get_args
from pydantic import BaseModel
from sqlalchemy import UUID, Column, ForeignKey, DateTime, Enum as SQLAEnum
from sqlalchemy.types import TypeDecorator
from sqlalchemy.orm import Session, Mapped, declarative_base
from sqlalchemy.dialects.postgresql import JSONB

Base: type = declarative_base()
Model = BaseModel
BaseEnum = Enum

class UIDColumn(Column):
    def __init__(
        self, primary_key: bool = False, fk: str | None = None, nullable: bool = False
    ):
        super().__init__(
            UUID(as_uuid=True), *(ForeignKey(fk) if fk else ()),
            primary_key=primary_key, nullable=nullable,
            default=uuid.uuid4 if primary_key else None
        )

class TimestampColumn(Column):
    def __init__(self, nullable: bool = False, default_now: bool = False):
        super().__init__(
            DateTime(timezone=True), nullable=nullable,
            default=datetime.now(timezone.utc) if default_now else None
        )

class EnumColumn(Column):
    def __init__(
        self, enum_cls: BaseEnum, nullable: bool = False, default: BaseEnum | None = None
    ):
        super().__init__(SQLAEnum(enum_cls), nullable=nullable, default=default)

class _ModelJSONB(TypeDecorator):
    impl = JSONB
    cache_ok = True
    model_cls: type[BaseModel]

    def __init__(self, model_cls: type[BaseModel], *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.model_cls = model_cls

    def process_bind_param(self, value: BaseModel | None, _dialect: Any):
        if value is None:
            return None

        return value.model_dump()

    def process_result_value(self, value: dict[str, Any] | None, _dialect: Any):
        if value is None:
            return None

        return self.model_cls(**value)

class ModelColumn(Column):
    def __init__(self, model_cls: type[BaseModel], nullable: bool = False):
        super().__init__(_ModelJSONB(model_cls), nullable=nullable)

class BaseMixin:
    __model__: type[Model] | None = None

    uid: Mapped[str] = UIDColumn(primary_key=True, nullable=False)

    @classmethod
    def get(cls, session: Session, uid: uuid.UUID) -> "BaseMixin":
        return session.query(cls).filter_by(uid=uid).first()

    def to_model(self, *, model_cls: type[Model] | None = None) -> Model:
        if not model_cls:
            model_cls = getattr(self, "__model__", None)

        if model_cls is None:
            raise NotImplementedError()

        data = {}
        for key, field in model_cls.model_fields.items():
            value = getattr(self, key)

            if isinstance(value, uuid.UUID):
                value = str(value)

            anno = field.annotation
            if get_origin(anno) is Union:
                anno = get_args(anno)[0]

            if isinstance(value, BaseMixin) and issubclass(anno, Model):
                value = value.to_model(model_cls=anno)

            is_checkable_list = isinstance(value, list) and len(value) > 0
            if is_checkable_list:
                if isinstance(value[0], BaseMixin):
                    inner_type = get_args(anno)[0]
                    value = [item.to_model(model_cls=inner_type) for item in value]

                if isinstance(value[0], uuid.UUID):
                    value = [str(item) for item in value]

            data[key] = value

        return model_cls(**data)
