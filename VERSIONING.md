# Versioning Strategy

Repo này dùng chiến lược versioning cho hợp đồng OpenAPI của Lab 02 theo nguyên tắc **ổn định contract trước, thay đổi có kiểm soát**.

## 1. Quy ước version

- `info.version` trong `openapi.yaml` phản ánh version của hợp đồng API.
- Chỉ tăng **patch** khi sửa mô tả, ví dụ hoặc wording mà không ảnh hưởng hành vi.
- Tăng **minor** khi thêm khả năng mới nhưng vẫn tương thích ngược.
- Tăng **major** khi có thay đổi ngắt quãng khiến consumer cũ có thể hỏng.

## 2. Thay đổi tương thích ngược

Các thay đổi sau được xem là backward-compatible và có thể đi vào minor release:

- thêm field mới nhưng để `required` ở mức hợp lý hoặc giữ là optional;
- thêm endpoint mới;
- thêm response example hoặc description;
- thêm giá trị mới vào enum nếu consumer được thiết kế để bỏ qua giá trị lạ;
- thêm header hoặc metadata mới mà client cũ có thể ignore.

Ví dụ với contract hiện tại:

- thêm trường optional mới vào response `DetectionResult`;
- thêm endpoint `GET /vision/models/info` cho Camera Stream kiểm tra model;
- mở rộng `Problem` với field optional mới nếu client vẫn đọc được payload cũ.

## 3. Thay đổi ngắt quãng

Các thay đổi sau là breaking change và phải được cân nhắc thành major release:

- xóa path hoặc operation đang được dùng;
- đổi tên field bắt buộc;
- đổi kiểu dữ liệu của field bắt buộc;
- đổi ý nghĩa của enum value hiện có;
- làm một field đang optional trở thành required;
- đổi format response theo cách làm client cũ không parse được.

Ví dụ:

- đổi `correlation_id` từ `uuid` sang một chuỗi tùy ý;
- xóa `frame_url` khỏi request detect;
- đổi `finding_type` khiến consumer cũ không còn phân biệt được request type.

## 4. Cách deprecate một endpoint hoặc field

Khi cần thay thế một endpoint cũ bằng endpoint mới:

- đánh dấu operation cũ bằng `deprecated: true` trong OpenAPI;
- giữ endpoint cũ hoạt động trong một khoảng thời gian chuyển tiếp;
- thêm mô tả rõ endpoint mới thay thế cái gì;
- nếu có kế hoạch tắt hẳn, gửi thông báo trước cho consumer.

Trong response hoặc header, có thể dùng `Sunset` để báo thời điểm ngừng hỗ trợ:

```http
Sunset: Wed, 30 Sep 2026 23:59:59 GMT
```

Nếu cần, có thể bổ sung thêm thông tin chuyển tiếp qua `Link` header trỏ tới endpoint mới hoặc tài liệu migration.

## 5. Áp dụng cho contract hiện tại

Đối với cặp Camera Stream ↔ AI Vision:

- ưu tiên mở rộng contract theo hướng thêm field/endpoint mới thay vì đổi schema hiện có;
- nếu phải thay thế một endpoint cũ, phải ghi rõ rationale trong `negotiation-log.md`;
- mọi thay đổi ảnh hưởng consumer phải được review lại bằng Spectral và Prism mock server trước khi chốt.

## 6. Tóm tắt thực hành

- Patch: chỉnh wording, example, hoặc mô tả.
- Minor: thêm khả năng mới nhưng không làm hỏng consumer cũ.
- Major: thay đổi làm consumer cũ không dùng được nữa.

Khi deprecate, dùng `deprecated: true` trong OpenAPI và thông báo ngừng bằng `Sunset` header để consumer có thời gian migrate.