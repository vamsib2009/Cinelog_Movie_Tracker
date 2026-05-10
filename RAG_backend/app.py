from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from agent.agent import run_agent
from rag.rag import run_rag, stream_rag
from schema.request import RagRequest
from schema.response import RagResponse

app = FastAPI(title="Cinelog RAG Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# human readable
@app.get('/')
def home():
    return {'message': 'Cinelog Movie App RAG Backend'}


# machine readable
@app.get('/health')
def health_check():
    return {'status': 'OK'}


@app.post('/search', response_model=RagResponse)
def search(req: RagRequest) -> RagResponse:
    return run_rag(req.query, req.max_suggestions, req.history)


@app.post('/search/stream')
def search_stream(req: RagRequest):
    return StreamingResponse(
        stream_rag(req.query, req.max_suggestions, req.history),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.post('/agent', response_model=RagResponse)
def agent_search(req: RagRequest) -> RagResponse:
    return run_agent(req.query, req.history, req.max_suggestions)

