#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:4010}"
AUTH_HEADER="Authorization: Bearer test-token"

echo "[Lab02] Testing Prism mock server at $BASE_URL"
echo

echo "[1/5] Happy path: GET /health"
curl --silent --show-error -i "$BASE_URL/health"
echo "
---"

echo "[2/5] Happy path: POST /vision/detect"
curl --silent --show-error -i -X POST "$BASE_URL/vision/detect" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "CAM-001",
    "correlation_id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2026-05-17T08:00:00Z",
    "frame_url": "https://cdn.campus.local/frames/cam-001-0001.jpg"
  }'
echo "
---"

echo "[3/5] Happy path: GET /vision/detections/{detectionId}"
curl --silent --show-error -i "$BASE_URL/vision/detections/0196fb3d-4ad7-7d1e-9f49-5d5148d2babc" -H "$AUTH_HEADER"
echo "
---"

echo "[4/5] Error case: POST /vision/detect invalid payload"
curl --silent --show-error -i -X POST "$BASE_URL/vision/detect" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{ "camera_id": "CAM-001" }'
echo "
---"

echo "[5/5] Error case: GET /vision/detections/{detectionId} with invalid UUID"
curl --silent --show-error -i "$BASE_URL/vision/detections/not-a-uuid" -H "$AUTH_HEADER"
echo
