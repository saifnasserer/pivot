#!/bin/bash

echo "🚀 Deploying Firebase Functions..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ You are not logged in to Firebase. Please run:"
    echo "   firebase login"
    exit 1
fi

# Deploy functions
echo "📦 Deploying functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo "✅ Functions deployed successfully!"
    echo ""
    echo "🔗 Your function URL will be:"
    echo "   https://us-central1-pivot-28563.cloudfunctions.net/send_notification"
    echo ""
    echo "📝 To test the function, you can use:"
    echo "   curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/send_notification \\"
    echo "     -H \"Content-Type: application/json\" \\"
    echo "     -d '{\"token\": \"YOUR_FCM_TOKEN\", \"title\": \"Test\", \"body\": \"Test message\"}'"
else
    echo "❌ Deployment failed!"
    exit 1
fi 