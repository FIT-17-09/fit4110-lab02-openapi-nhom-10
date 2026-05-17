# Phân tích yêu cầu — vai Consumer

- Cặp đàm phán: pair-01-camera-ai-vision
- Product: Smart Campus
- Consumer service: Camera Stream Service
- Provider service: AI Vision Service
- Người viết: Nhóm 10
- Ngày: 2026-05-17
- Trạng thái: Đã hoàn thiện và kiểm thử thành công (100%)

---

## 1. Resource Consumer cần nhận/gửi

| Resource | Consumer dùng để làm gì? | Field bắt buộc với Consumer | Field có thể tùy chọn |
|---|---|---|---|
| DetectRequest | Gửi frame URL lên AI Vision khi phát hiện motion | camera_id, correlation_id, timestamp, frame_url | mime_type, confidence_threshold |
| DetectionResult | Nhận kết quả để quyết định có forward sang Core Business hay không | detection_id, camera_id, correlation_id, anomaly_detected, objects, risk_level, confidence_score, processed_at | model_version, note |
| Finding | Hiển thị object/người được phát hiện trong ảnh | finding_type, label, confidence | bounding_box, person_id, object_category |
| ModelInfo | Kiểm tra model AI đang dùng có hỗ trợ loại object cần detect không | model_id, version, supported_labels, last_updated | input_modes |
| HealthStatus | Kiểm tra trạng thái service trước khi gửi frame | status, service, time | — |

---

## 2. API Consumer cần gọi

| Method | Path | Lúc nào gọi? | Kỳ vọng response |
|---|---|---|---|
| GET | `/health` | Trước khi bắt đầu gửi frame hoặc định kỳ health check | `200` với status `ok` |
| POST | `/vision/detect` | Ngay khi Camera Stream phát hiện motion | `200` với `detection_id` và kết quả detect |
| GET | `/vision/detections/{detectionId}` | Khi cần tra cứu lại kết quả cũ để đối chiếu | `200` với đầy đủ thông tin detection |
| GET | `/vision/models/info` | Khi khởi động service để kiểm tra model tương thích | `200` với danh sách supported_labels |

---

## 3. Error case Consumer cần xử lý

Tối thiểu 5 case.

| Status | Consumer hiểu là gì? | Consumer sẽ xử lý thế nào? |
|---:|---|---|
| 400 | Request sai schema | Sửa payload/log lỗi |
| 401 | Thiếu token | Refresh/cấu hình token |
| 404 | Không tìm thấy resource | Hiển thị trạng thái không tồn tại |
| 422 | Vi phạm rule nghiệp vụ hoặc frame_url không hợp lệ | Hiển thị lý do cụ thể |
| 500 | Lỗi nội bộ provider | Retry theo chính sách hoặc báo lỗi vận hành |

---

## 4. Giả định bổ sung

- `correlation_id` được Camera Stream tạo ra và phải giữ nguyên xuyên suốt retry.
- `confidence_score` có thể là `null` nếu không có anomaly.
- `risk_level` mặc định `LOW` khi `objects` rỗng.
- Camera Stream ưu tiên gửi ảnh bằng URL nội bộ, chỉ fallback sang cách khác nếu hai bên thống nhất sau.

---

## 5. Câu hỏi cho Provider

1. Nếu `frame_url` không truy cập được thì Provider trả `422` hay `404`?
2. `confidence_score` có được phép là `null` khi `risk_level = LOW` không?
3. Provider có đảm bảo `detection_id` và `correlation_id` luôn xuất hiện để audit không?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Provider đổi kiểu dữ liệu của `risk_level` | Consumer parse lỗi hoặc logic sai | Chốt enum rõ ràng trong `openapi.yaml` |
| Provider thiếu mã lỗi cụ thể | Consumer khó phân biệt lỗi để xử lý đúng | Chuẩn hóa `Problem Details` với `errors[]` |
| Độ trễ AI Vision cao khi tải lớn | Camera bị block chờ response | Thống nhất timeout và cơ chế retry |
| `frame_url` không accessible từ AI Vision | `422` hoặc `500` không rõ nguyên nhân | Quy định rõ URL phải trong campus network |
