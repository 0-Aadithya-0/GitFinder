FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

# Step 1: Install torch CPU wheel explicitly FIRST using --index-url (forces
# that index exclusively). --extra-index-url on the main install does NOT
# guarantee CPU torch — pip may still pick the CUDA wheel from PyPI.
RUN pip install --no-cache-dir torch \
    --index-url https://download.pytorch.org/whl/cpu

# Step 2: Install the rest of the dependencies. torch is already present so
# sentence-transformers will not re-install it.
RUN pip install --no-cache-dir -r requirements.txt

# Pre-bake the sentence-transformers model into the image layer.
# Without this, the first request triggers a 30-60s download and times out.
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
