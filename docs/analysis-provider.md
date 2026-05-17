# Phân tích yêu cầu — vai Provider

- Cặp đàm phán: pair-01-camera-ai-vision
- Product: Smart Campus
- Provider service: AI Vision Service
- Consumer service: Camera Stream Service
- Người viết: Nhóm 10
- Ngày: 2026-05-17

---

## 0. Service boundary

- Upstream: Camera Stream gửi frame hoặc metadata khi phát hiện motion.
- Downstream: AI Vision trả kết quả detect cho Camera Stream để xử lý tiếp.

---

## 1. Resource chính

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| DetectRequest | Yêu cầu AI Vision phân tích frame | camera_id, correlation_id, timestamp, frame_url | mime_type, confidence_threshold |
| DetectionResult | Kết quả detect trả ngay cho Camera Stream | detection_id, camera_id, correlation_id, anomaly_detected, objects, risk_level, confidence_score, processed_at | model_version, note |
| Finding | Một object hoặc một người được phát hiện | finding_type, label, confidence | bounding_box, person_id, object_category |
| ModelInfo | Thông tin model AI đang chạy | model_id, version, supported_labels, last_updated | input_modes |
| HealthStatus | Trạng thái service | status, service, time | — |

---

## 2. Action/API dự kiến

| Method | Path | Mục đích | Consumer gọi khi nào? |
|---|---|---|---|
| GET | `/health` | Kiểm tra trạng thái service | Trước khi gửi frame hoặc khi monitor |
| POST | `/vision/detect` | Nhận frame URL từ Camera Stream và trả kết quả detect đồng bộ | Khi Camera phát hiện motion |
| GET | `/vision/detections/{detectionId}` | Lấy chi tiết một detection đã trả về trước đó | Khi cần audit/tra cứu |
| GET | `/vision/models/info` | Lấy thông tin model AI đang dùng | Khi muốn kiểm tra khả năng hỗ trợ |

---

## 3. Error case

Tối thiểu 5 case.

| Status | Tình huống | Response body dự kiến |
|---:|---|---|
| 400 | Payload sai định dạng JSON hoặc thiếu trường bắt buộc | `Problem` với `errors[]` chỉ rõ field lỗi |
| 401 | Thiếu hoặc sai Bearer token | `Problem` |
| 404 | `detection_id` không tồn tại trong hệ thống | `Problem` |
| 422 | `frame_url` không đúng pattern hoặc nội dung ảnh không thể detect | `Problem` |
| 500 | Lỗi nội bộ AI model hoặc downstream service | `Problem` |

---

## 4. Giả định bổ sung

Ghi rõ những điểm user story chưa nói nhưng Provider cần giả định.

- AI Vision xử lý đồng bộ và trả kết quả ngay, không cần polling.
- `correlation_id` là bắt buộc để Camera Stream đối chiếu audit và chống xử lý lặp.
- `frame_url` là input chính; nếu ảnh không hợp lệ thì trả `422`.
- Khi không có anomaly, `confidence_score` nhận `null` và `risk_level` mặc định `LOW`.
- `Finding` được mô hình hóa bằng `oneOf` + `discriminator` để tách `PersonFinding` và `ObjectFinding`.

---

## 5. Câu hỏi cho Consumer

1. Camera Stream muốn gửi `frame_url` hay có cần fallback sang base64/multipart không?
2. Khi `risk_level` là `LOW`, Consumer có muốn `objects` là mảng rỗng hay vẫn gửi các finding mức thấp?
3. Camera Stream có cần `model_id` và `supported_labels` để hiển thị trạng thái model không?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| URL ảnh không truy cập được | Trả 422, Camera Stream phải retry | Chốt trước `frame_url` phải nằm trong mạng nội bộ |
| Trùng request khi retry | Kết quả bị tạo lặp | Bắt buộc `correlation_id` |
| Không thống nhất giá trị `confidence_score` khi không có anomaly | Consumer hiểu sai logic | Quy định `confidence_score = null` và `risk_level = LOW` |
