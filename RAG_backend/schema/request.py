from typing import Literal

from pydantic import BaseModel, Field


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class RagRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=500)
    max_suggestions: int = Field(default=3, ge=1, le=10)
    # Prior conversation: up to 3 turns = 6 messages (3 user + 3 assistant).
    history: list[ChatTurn] = Field(default_factory=list, max_length=6)
