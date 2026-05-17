# Kịch bản kiểm thử tự động mock server bằng curl
# Sử dụng: .\scripts\test_mock_with_curl.ps1
$ErrorActionPreference = "Stop"

$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:4010" }
$AuthHeader = "Authorization: Bearer test-token"

Write-Host "[Lab02] Testing Prism mock server at $BaseUrl"
Write-Host ""

function Invoke-Lab02Request {
  param(
    [string]$Label,
    [string]$Method,
    [string]$Path,
    [string]$Body = $null,
    [hashtable]$Headers = @{}
  )

  Write-Host $Label

  $invokeParams = @{
    Method = $Method
    Uri = "$BaseUrl$Path"
    Headers = $Headers
    UseBasicParsing = $true
  }

  if (-not [string]::IsNullOrWhiteSpace($Body)) {
    $invokeParams.Body = $Body
    $invokeParams.ContentType = "application/json"
  }

  try {
    $response = Invoke-WebRequest @invokeParams
    Write-Host "HTTP/1.1 $($response.StatusCode) $($response.StatusDescription)"
    foreach ($headerName in $response.Headers.Keys) {
      Write-Host ("{0}: {1}" -f $headerName, $response.Headers[$headerName])
    }
    Write-Host ""
    Write-Host $response.Content
  } catch {
    $response = $_.Exception.Response
    if ($null -eq $response) {
      throw
    }

    $statusCode = [int]$response.StatusCode
    $statusDescription = $response.StatusDescription
    Write-Host "HTTP/1.1 $statusCode $statusDescription"
    foreach ($headerName in $response.Headers.Keys) {
      Write-Host ("{0}: {1}" -f $headerName, $response.Headers[$headerName])
    }
    Write-Host ""

    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    Write-Host $reader.ReadToEnd()
  }
}

Invoke-Lab02Request -Label "[1/5] Happy path: GET /health" -Method "GET" -Path "/health"
Write-Host "`n---"

Invoke-Lab02Request -Label "[2/5] Happy path: POST /vision/detect" -Method "POST" -Path "/vision/detect" -Body (@{
  camera_id = "CAM-001"
  correlation_id = "550e8400-e29b-41d4-a716-446655440000"
  timestamp = "2026-05-17T08:00:00Z"
  frame_url = "https://cdn.campus.local/frames/cam-001-0001.jpg"
} | ConvertTo-Json -Compress) -Headers @{ Authorization = "Bearer test-token" }
Write-Host "`n---"

Invoke-Lab02Request -Label "[3/5] Happy path: GET /vision/detections/{detectionId}" -Method "GET" -Path "/vision/detections/0196fb3d-4ad7-7d1e-9f49-5d5148d2babc" -Headers @{ Authorization = "Bearer test-token" }
Write-Host "`n---"

Invoke-Lab02Request -Label "[4/5] Error case: POST /vision/detect invalid payload" -Method "POST" -Path "/vision/detect" -Body '{"camera_id":"CAM-001"}' -Headers @{ Authorization = "Bearer test-token" }
Write-Host "`n---"

Invoke-Lab02Request -Label "[5/5] Error case: GET /vision/detections/{detectionId} with invalid UUID" -Method "GET" -Path "/vision/detections/not-a-uuid" -Headers @{ Authorization = "Bearer test-token" }
Write-Host ""
