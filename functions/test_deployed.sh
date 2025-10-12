#!/bin/bash

# Quick test script to verify deployed endpoints are responding
# This tests basic connectivity - full tests require Firebase ID token

echo "════════════════════════════════════════════════════════"
echo "  Testing Deployed Backblaze B2 Endpoints"
echo "════════════════════════════════════════════════════════"
echo ""

BASE_URL="https://us-central1-pivot-28563.cloudfunctions.net"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d '{}' \
        --max-time 10)
    
    # We expect 400 (bad request) because we're not sending proper data
    # But this confirms the endpoint is live and responding
    if [ "$response" == "400" ] || [ "$response" == "401" ]; then
        echo -e "${GREEN}✓ LIVE${NC} (HTTP $response - endpoint responding)"
    elif [ "$response" == "000" ]; then
        echo -e "${RED}✗ TIMEOUT${NC} (endpoint not responding)"
    else
        echo -e "${YELLOW}? UNKNOWN${NC} (HTTP $response)"
    fi
}

echo "1️⃣  Testing Generate Upload URL"
test_endpoint "generate_upload_url" "$BASE_URL/generate_upload_url"

echo ""
echo "2️⃣  Testing Confirm Material Upload"
test_endpoint "confirm_material_upload" "$BASE_URL/confirm_material_upload"

echo ""
echo "3️⃣  Testing Refresh Download URL"
test_endpoint "refresh_download_url" "$BASE_URL/refresh_download_url"

echo ""
echo "4️⃣  Testing Delete Material File"
test_endpoint "delete_material_file" "$BASE_URL/delete_material_file"

echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "✅ Connectivity Test Complete!"
echo ""
echo "📝 Note: These tests verify endpoints are deployed and responding."
echo "   For full testing with actual uploads, you need:"
echo "   1. A valid Firebase ID token"
echo "   2. Use Postman collection: Backblaze_API_Tests.postman_collection.json"
echo "   3. Or use curl commands in DEPLOYED_ENDPOINTS.md"
echo ""
echo "🔍 To get a Firebase ID token:"
echo "   - From Flutter: await FirebaseAuth.instance.currentUser?.getIdToken()"
echo "   - Or use Firebase Console → Authentication"
echo ""
echo "════════════════════════════════════════════════════════"

