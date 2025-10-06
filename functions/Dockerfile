# Use Python 3.12 slim image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy function code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1000 functionuser && chown -R functionuser:functionuser /app
USER functionuser

# Expose port (Firebase Functions uses different ports, but this is for local testing)
EXPOSE 8080

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Command to run the functions locally (for testing)
# For actual Firebase deployment, use: firebase deploy --only functions
CMD ["python", "-m", "functions_framework", "--target=send_notification", "--port=8080", "--host=0.0.0.0"]

