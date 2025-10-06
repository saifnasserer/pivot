#!/bin/bash

# Pivot Functions Docker Deployment Script
# This script builds and deploys Firebase functions using Docker

set -e  # Exit on any error

echo "🚀 Starting Pivot Functions deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    print_error "You are not logged in to Firebase. Please run:"
    echo "firebase login"
    exit 1
fi

# Get the deployment mode
DEPLOY_MODE=${1:-"firebase"}

case $DEPLOY_MODE in
    "local")
        print_status "Building Docker image for local testing..."
        docker build -t pivot-functions:latest .
        
        print_status "Starting local container..."
        docker run -d -p 8080:8080 --name pivot-functions-local pivot-functions:latest
        
        print_success "Local deployment complete!"
        print_status "Functions available at: http://localhost:8080"
        print_status "To stop: docker stop pivot-functions-local"
        print_status "To remove: docker rm pivot-functions-local"
        ;;
        
    "compose")
        print_status "Starting with Docker Compose..."
        docker-compose up -d --build
        
        print_success "Docker Compose deployment complete!"
        print_status "Functions available at: http://localhost"
        print_status "To stop: docker-compose down"
        ;;
        
    "firebase"|*)
        print_status "Building Docker image..."
        docker build -t pivot-functions:latest .
        
        print_status "Testing functions locally..."
        docker run -d -p 8080:8080 --name pivot-functions-test pivot-functions:latest
        
        # Wait for container to start
        sleep 5
        
        # Test the function
        if curl -f http://localhost:8080 > /dev/null 2>&1; then
            print_success "Local test passed!"
        else
            print_warning "Local test failed, but continuing with Firebase deployment..."
        fi
        
        # Clean up test container
        docker stop pivot-functions-test > /dev/null 2>&1 || true
        docker rm pivot-functions-test > /dev/null 2>&1 || true
        
        print_status "Deploying to Firebase..."
        firebase deploy --only functions
        
        print_success "Firebase deployment complete!"
        ;;
esac

print_success "🎉 Deployment finished successfully!"

