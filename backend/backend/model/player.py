from datetime import datetime
from sqlalchemy import String, Column
from sqlalchemy.orm import Session

from backend.base import Model, Base, BaseMixin, TimestampColumn

class PlayerModel(Model):
    uid: str
    tag: str
    queued_at: datetime | None

class Player(Base, BaseMixin):
    __tablename__ = "players"
    __model__ = PlayerModel

    tag = Column(String, nullable=False)
    queued_at = TimestampColumn(nullable=True)

    @classmethod
    def get_by_tag(cls, session: Session, tag: str) -> "Player" | None:
        return session.query(cls).filter_by(tag=tag).first()
