# Redis ECS Testing - Example Application
#
# Build:
#   docker build -t redis-test-app .
#
# Run locally:
#   docker run -e REDIS_HOST=localhost -e REDIS_PORT=6379 redis-test-app
#
# Push to ECR:
#   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com
#   docker tag redis-test-app:latest <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/redis-test-app:latest
#   docker push <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/redis-test-app:latest

FROM python:3.11-slim

# Install dependencies
RUN pip install --no-cache-dir redis

# Copy application
WORKDIR /app
COPY app.py .

# Run as non-root user
RUN useradd -m appuser
USER appuser

# Default command
CMD ["python", "app.py"]
