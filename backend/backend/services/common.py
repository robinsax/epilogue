from fastapi import Depends, Request
from sqlalchemy.orm import Session

from backend.base import Invalid, get_session
from backend.model import Player

def get_player(req: Request, session: Session = Depends(get_session)) -> Player:
    # TODO: This is dummy authentication.
    tag = req.headers.get("X-Player-Tag")
    if not tag:
        raise Invalid("missing_tag")

    player = Player.get_by_tag(session, tag)
    if not player:
        raise Invalid("invalid_tag")

    return player
