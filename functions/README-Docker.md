# Pivot Functions - Docker Deployment

This directory contains Docker configuration for deploying Pivot Firebase Functions.

## Quick Start

### 1. Local Testing with Docker

```bash
# Build and run locally
docker build -t pivot-functions .
docker run -p 8080:8080 pivot-functions

# Or use Docker Compose
docker-compose up --build
```

### 2. Deploy to Firebase (Recommended)

```bash
# Use the deployment script
./deploy.sh

# Or manually
firebase deploy --only functions
```

## Available Functions

- `send_notification` - Send push notifications
- `sync_remote_config` - Sync remote configuration
- `delete_user_auth` - Delete user authentication
- `get_profile_image_urls` - Get profile image URLs

## Deployment Options

The `deploy.sh` script supports different deployment modes:

```bash
# Deploy to Firebase (default)
./deploy.sh firebase

# Local testing only
./deploy.sh local

# Docker Compose deployment
./deploy.sh compose
```

## Environment Variables

For local testing, you may need to set:

- `GOOGLE_APPLICATION_CREDENTIALS` - Path to service account key
- `PORT` - Port number (default: 8080)

## Development

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally with functions-framework
functions-framework --target=send_notification --port=8080

# Test endpoints
curl -X POST http://localhost:8080/send_notification \
  -H "Content-Type: application/json" \
  -d '{"token":"test","title":"Test","body":"Test message"}'
```

### Docker Development

```bash
# Build image
docker build -t pivot-functions:dev .

# Run with volume mount for development
docker run -p 8080:8080 -v $(pwd):/app pivot-functions:dev
```

## Production Deployment

For production deployment to Firebase:

1. Ensure you're logged in: `firebase login`
2. Run: `./deploy.sh` or `firebase deploy --only functions`
3. Functions will be available at Firebase URLs

## Troubleshooting

### Common Issues

1. **Permission denied**: Make sure `deploy.sh` is executable:

   ```bash
   chmod +x deploy.sh
   ```

2. **Docker build fails**: Check Docker is running and you have sufficient disk space

3. **Firebase deployment fails**: Ensure you're logged in and have proper permissions

4. **Functions not accessible**: Check Firebase console for deployment status

### Logs

```bash
# Docker logs
docker logs pivot-functions-local

# Firebase logs
firebase functions:log
```

## Security Notes

- Never commit service account keys to version control
- Use environment variables for sensitive configuration
- The Dockerfile creates a non-root user for security
- CORS is properly configured for cross-origin requests

