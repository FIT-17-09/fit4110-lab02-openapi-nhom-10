# Biên bản đàm phán hợp đồng API

- Cặp đàm phán: pair-01-camera-ai-vision
- Product: Smart Campus
- Provider: Service A4 (AI Vision) - Nhóm 10
- Consumer: Service A2 (Camera Stream) - Nhóm 01
- Phiên: v1.0
- Ngày: 15/05/2026

---

## Issue #1

- Raised by: Consumer
- Endpoint: `POST /api/v1/vision/detect`
- Concern: Định dạng dữ liệu ảnh truyền đi như thế nào để giảm tải băng thông mạng nội bộ?
- Proposal: Consumer gửi URL chứa ảnh (`frame_url`) thay vì mã hoá ảnh Base64 nén vào body JSON.
- Resolution: Accepted
- Rationale: Gửi Base64 làm phình to payload, có thể gây nghẽn RAM trên hệ thống tích hợp API Gateway. Dùng URL (internal) là tối ưu hơn vì AI tự tải về xử lý.
- Impact: Cần thiết kế thuộc tính `frame_url` format `uri` vào schema request body.

---

## Issue #2

- Raised by: Consumer
- Endpoint: `POST /api/v1/vision/detect`
- Concern: Camera Stream đẩy sự kiện liên tục, AI có trả kết quả trực tiếp luôn không?
- Proposal: Thiết kế API chạy đồng bộ (Sync REST), trả thẳng về thông tin dị thường ở HTTP 200 OK để quy trình alert mạch lạc.
- Resolution: Accepted
- Rationale: Các model AI Vision hiện tại đã được tối ưu để Inference rất nhanh (<500ms), hoàn toàn có thể trả thẳng kết quả.
- Impact: Endpoint `/detect` trả về ngay lập tức schema `DetectionResult`.

---

## Issue #3

- Raised by: Provider
- Endpoint: `POST /api/v1/vision/detect`
- Concern: Nếu URL ảnh gửi sang bị hỏng hoặc chất lượng ảnh quá mờ (không thể detect) thì xử lý thế nào?
- Proposal: Trả về mã lỗi HTTP 422 (Unprocessable Entity) thay vì lỗi 400 hoặc 500, đính kèm cấu trúc Problem Details giải thích lý do.
- Resolution: Accepted
- Rationale: Giúp Consumer phân biệt giữa lỗi format request (400) và lỗi nội dung nghiệp vụ (422) để biết cách ghi log.
- Impact: Bổ sung mã lỗi 422 vào danh sách response của endpoint.

---

## Issue #4

- Raised by: Consumer
- Endpoint: `GET /api/v1/vision/detections/{detectionId}`
- Concern: Nếu Consumer lỡ bị đứt kết nối mạng lúc gọi POST, kết quả phát hiện có bị mất vĩnh viễn không?
- Proposal: Thêm 1 API phụ cho phép tra cứu lại kết quả nhận diện đã chạy bằng `detectionId`.
- Resolution: Accepted
- Rationale: Tăng tính bền vững của luồng dữ liệu, cho phép Consumer tự phục hồi khi có sự cố mạng chập chờn.
- Impact: Bổ sung endpoint `GET /api/v1/vision/detections/{detectionId}`.

---

## Issue #5

- Raised by: Provider
- Endpoint: `POST /api/v1/vision/detect`
- Concern: Cần làm rõ Consumer sẽ phân biệt việc phát hiện ra "Người lạ" và phát hiện ra "Đồ vật vô chủ" như thế nào qua API?
- Proposal: Dùng tính năng Đa hình (Polymorphism) bằng `oneOf` + `discriminator` để phân nhánh model kết quả: `PersonFinding` và `ObjectFinding`.
- Resolution: Accepted
- Rationale: Dữ liệu trả về sẽ tường minh và dễ mở rộng.
- Impact: Cập nhật schema `Finding` trong OpenAPI.

---

## Issue #6

- Raised by: Consumer
- Endpoint: `POST /api/v1/vision/detect`
- Concern: Nếu ảnh bình thường, không có dị thường gì, thì thông số độ tin cậy `confidence_score` sẽ là bao nhiêu?
- Proposal: Nếu cờ `anomaly_detected: false` thì giá trị `confidence_score` sẽ nhận là `null`.
- Resolution: Accepted
- Rationale: Rõ ràng về mặt ngữ nghĩa (Semantics), tránh gửi score ảo (ví dụ 0.0 hoặc -1) gây nhầm lẫn logic cho Consumer.
- Impact: Cấu hình `confidence_score` thành kiểu union type `["number", "null"]`.

---

# Chốt hợp đồng v1.0

Provider sign-off: Nhóm 10
Consumer sign-off: Nhóm 1
Witness (GV/TA): Giảng viên hướng dẫn
Date: 15/05/2026
