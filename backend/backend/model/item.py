from sqlalchemy import String, Column, Integer

from backend.base import Model, Base, BaseMixin, UIDColumn

class ItemModel(Model):
    uid: str
    type_ref: str
    home_uid: str | None
    match_uid: str | None
    attachment_uid: str | None
    attachment_type: str | None
    attachment_path: str | None
    stack_size: int | None

class Item(Base, BaseMixin):
    """
    Instance of an item.
    """
    __tablename__ = "items"
    __model__ = ItemModel

    type_ref = Column(String, nullable=False)
    home_uid = UIDColumn(fk="players.uid", nullable=True)
    match_uid = UIDColumn(fk="matches.uid", nullable=True)
    player_attachment_uid = UIDColumn(fk="players.uid", nullable=True)
    item_attachment_uid = UIDColumn(fk="items.uid", nullable=True)
    attachment_path = Column(String, nullable=True)
    stack_size = Column(Integer, nullable=True)

    @property
    def attachment_uid(self):
        return self.player_attachment_uid or self.item_attachment_uid

    @property
    def attachment_type(self):
        if self.player_attachment_uid:
            return "player"
        if self.item_attachment_uid:
            return "item"

        return None
