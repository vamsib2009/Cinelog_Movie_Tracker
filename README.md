# Cinelog Movie Tracker

Cinelog is a full-stack movie tracking and recommendation application that combines traditional movie management features with AI-assisted discovery.

The application allows users to browse and manage movies, maintain watchlists and favorites, discover trending content, and interact with an AI-powered movie assistant for recommendations and movie-related queries.

## Tech Stack

- Spring Boot
- FastAPI
- LangChain
- PostgreSQL + pgvector
- Flutter
- Docker
- AWS
- Neon
- OpenAI Embeddings
- CLIP
- OMDb API

## Current Progress

### Backend (Spring Boot)
Implemented a Spring Boot backend connected to PostgreSQL for:

- movie catalog management
- user persistence
- favorites
- watchlist management
- trending movie support

Movie metadata is ingested from the OMDb API and stored in PostgreSQL.

Vector support is enabled using pgvector for recommendation-related features.

---

### Recommendation System
Implemented embedding-based recommendation infrastructure:

- OpenAI embeddings for plot and metadata similarity
- CLIP embeddings for poster similarity comparisons
- vector storage and similarity search support in PostgreSQL

Currently implemented:
- semantic movie similarity foundation
- poster similarity matching infrastructure

---

### AI Assistant (FastAPI + LangChain)
Built a FastAPI service containing a LangChain ReAct agent with tool calling support.

Current tools include:

- PostgreSQL movie database lookup
- DuckDuckGo web search
- Wikipedia search
- nearby movie discovery support

The assistant is designed to answer movie-related questions and provide recommendations using both internal movie data and external information sources.

---

### Frontend (Flutter)
Designed and developed the Flutter frontend application.

Current work includes:

- movie browsing UI
- watchlist/favorites integration
- chatbot interface
- frontend integration with backend services

Flutter Web deployment is currently available.

---

### Deployment
Current deployment setup:

- Spring Boot backend deployed on AWS
- FastAPI AI backend deployed on AWS
- Flutter Web frontend hosted on AWS S3
- PostgreSQL database hosted on Neon

---

## Project Structure

- `SpringEcom/` — Spring Boot backend
- `RAG_backend/` — FastAPI + LangChain AI backend
- `flutter_part/mobile_flutter_app/` — Flutter frontend
- `Cinelog_Scrapers/` — scraping / data preparation utilities
- `Streamlit_Files/` — earlier experimental UI/prototyping work

---

## Upcoming Work

Planned improvements:

- stronger recommendation ranking logic
- hybrid recommendation retrieval
- improved chatbot reasoning and tool orchestration
- better nearby theater discovery via dedicated APIs
- authentication and authorization
- user progress/history tracking
- production hardening and monitoring
- cleaner deployment automation

## Status

This project is actively under development.
