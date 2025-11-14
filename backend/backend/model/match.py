from datetime import datetime

from backend.base import (
    Model, Base, BaseMixin, BaseEnum, TimestampColumn, UIDColumn, EnumColumn
)

class MatchModel(Model):
    uid: str
    started_at: datetime
    ended_at: datetime | None

class Match(Base, BaseMixin):
    __tablename__ = "matches"
    __model__ = MatchModel

    started_at = TimestampColumn(nullable=False, default_now=True)
    ended_at = TimestampColumn(nullable=True)

class PlayerMatchResult(BaseEnum):
    PENDING = "pending"
    DIED = "died"
    SURVIVED = "survived"

class PlayerMatchModel(Model):
    uid: str
    match_uid: str
    player_uid: str
    result: PlayerMatchResult

class PlayerMatch(Base, BaseMixin):
    __tablename__ = "player_matches"
    __model__ = PlayerMatchModel

    player_uid = UIDColumn(fk="players.uid", nullable=False)
    match_uid = UIDColumn(fk="matches.uid", nullable=False)
    result = EnumColumn(
        PlayerMatchResult, nullable=False, default=PlayerMatchResult.PENDING
    )
