# GitFinder 🔍

A full-stack application that semantically analyzes GitHub repositories, clusters them by "vibe" using vector embeddings, and visualizes the results as an interactive 2D scatter plot.

---

## Architecture & Data Flow

The following diagram shows the end-to-end GitFinder architecture, including the Flutter client, FastAPI backend, GitHub API integration, Qdrant vector database, embedding pipeline, and visualization flow.

![GitFinder Architecture](./docs/GitFinder-Architecture.png)

### Request Flow

1. The user enters a GitHub search query or repository URL in the Flutter web application.
2. Flutter debounces the input and sends a `POST /analyze` request through its data-source layer.
3. The FastAPI backend applies CORS middleware and routes the request to the analysis service.
4. The analysis service determines whether the request is a repository search or a specific repository lookup.
5. GitHub repository metadata is fetched through the GitHub API, with rate-limit handling and retries.
6. Repository data is passed through the shared ML pipeline:
   - Clean Markdown / repository text
   - Generate embeddings with `all-MiniLM-L6-v2`
   - Store/query vectors in Qdrant
   - Reduce embeddings to 2D coordinates
   - Normalize coordinates for visualization
7. The backend returns structured repository data and coordinates to the Flutter client.
8. Flutter renders the results using a 2D scatter chart and radar-based repository comparison views.

---

## Project Structure

```
GitFinder/
├── frontend/   # Flutter Web/Mobile app
└── backend/    # Python FastAPI service + ML pipeline
```

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Web/Mobile), `fl_chart`, `dio` |
| Backend | Python FastAPI |
| Vector DB | Qdrant |
| ML | `sentence-transformers` (`all-MiniLM-L6-v2`, local) |
| Infrastructure | Docker Compose |
| Web Server | Nginx |

---

## Frontend

Located in [`frontend/`](./frontend/).

A Flutter application (Web + Mobile) that provides the UI for submitting GitHub usernames, triggering analysis, and rendering the interactive vibe-map scatter plot.

**Key files:**
- `lib/main.dart` — app entry point
- `lib/analyze/` — feature module (BLoC, use cases, repositories, data sources)
- `lib/app_theme.dart` / `lib/router/app_router.dart` — theming and routing
- `Dockerfile` — containerized Flutter web build served via Nginx
- `nginx.conf` — Nginx config for serving the web build

**Run locally:**
```bash
cd frontend
flutter pub get
flutter run -d chrome   # web
# or
flutter run             # mobile
```

**Docker:**
```bash
cd frontend
docker build -t gitfinder-frontend .
docker run -p 80:80 gitfinder-frontend
```

---

## Backend

Located in [`backend/`](./backend/).

A Python FastAPI service that fetches GitHub repository data, vectorizes it using sentence-transformers, stores embeddings in Qdrant, and returns clustered results.

**Key files:**
- `main.py` — FastAPI app entry point
- `api/routers/analyze.py` — `/analyze` endpoint
- `repositories/` — GitHub + Qdrant data access
- `services/` — analyze, vectorization, and dimensionality-reduction services
- `requirements.txt` — Python dependencies
- `Dockerfile` — containerized FastAPI service

**Run locally:**
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

**Docker:**
```bash
cd backend
docker build -t gitfinder-backend .
docker run -p 8000:8000 gitfinder-backend
```

---

## Running the Full Stack

Use Docker Compose from the repo root (compose file coming soon):

```bash
docker compose up
```

| Service | URL |
|---|---|
| Frontend | http://localhost:80 |
| Backend API | http://localhost:8000 |
| Qdrant | http://localhost:6333 |

---

## Contributing

- `frontend` branch — Flutter app work
- `backend` branch — API + ML pipeline work
- `main` branch — merged, production-ready code
