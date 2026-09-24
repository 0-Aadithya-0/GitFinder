# GitFinder 🔍

A full-stack application that semantically analyzes GitHub repositories, clusters them by "vibe" using vector embeddings, and visualizes the results as an interactive 2D scatter plot.

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
| ML | `sentence-transformers` (all-MiniLM-L6-v2, local) |
| Infrastructure | Docker Compose |

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
