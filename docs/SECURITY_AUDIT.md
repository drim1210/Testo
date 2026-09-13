# SECURITY_AUDIT.md — Testo

**Ngày audit:** 2026-09-13
**Phạm vi:** backend FastAPI + mobile Flutter + git history + cấu hình Android
**Phương pháp:** quét secrets (working tree + toàn bộ git objects), static review từng endpoint (ownership, validation, error leakage), kiểm tra SQLi / path traversal / DoS surface, rate-limit + payload test tự động (`backend/tests/integration/test_security.py`, 11 test).

---

## 1. Đã khắc phục trong audit này

| # | Lỗ hổng | Mức độ | Fix |
|---|---|---|---|
| A1 | **IDOR**: `POST /sessions/{exam_id}/start` không kiểm tra exam thuộc user → người dùng khác đoán được exam_id có thể làm đề và xem kết quả topic breakdown | **High** | `session_service.start_session` lọc theo `Exam.user_id`; regression test `test_idor_cannot_take_other_users_exam` |
| A2 | **Không có rate limiting ở bất kỳ đâu** — flood `/auth/anonymous` tạo vô hạn user; flood `/exams/` đốt tiền LLM API không kiểm soát | **High** | Sliding-window limiter (`app/core/rate_limit.py`): 300 req/min/IP global; **auth: 5 lần/15 phút** (per IP + per device_id); generation: 10 lần/phút/user (exams + practice) |
| A3 | Upload chỉ kiểm tra MIME header — file đổi phần mềm (exe đổi tên .pdf) vẫn được accepted và đưa vào pdfplumber | Medium | Kiểm tra magic bytes `%PDF-` + sanitize filename (chống path traversal, control chars, giới hạn 200 ký tự) |
| A4 | Body JSON không giới hạn kích thước (memory DoS qua payload khổng lồ) | Medium | Middleware 413: >1MB cho JSON endpoints, >50MB+2MB tuyệt đối (upload có cap riêng ở service) |
| A5 | `device_id`, `scope`, `time_spent`, question_id… không chặn ký tự lạ / độ dài | Low | Pattern `^[A-Za-z0-9._-]+$` cho device_id; length caps toàn schemas; `time_spent` 0–86400; enum đã có sẵn |
| A6 | Path ID tùy ý (`/documents/../../x`) đi xuống tận DB query | Low | Middleware validate UUID cho `documents/exams/sessions/{id}` → 404 sớm |
| A7 | Mobile `LogInterceptor(requestBody: true)` log cả Authorization header ra logcat ở release build (JWT rò rỉ trên thiết bị root) | Low | Tắt body/header logging; chỉ giữ method-level logs |
| A8 | Server âm thầm chạy với SECRET_KEY mặc định nếu quên cấu hình | Medium | Startup guard: `ENVIRONMENT=production` + secret mặc định/ngắn → từ chối boot |
| A9 | **429/quota LLM bị nhầm là "câu hỏi không hợp lệ"** → validator âm thầm loại toàn bộ câu hỏi, user nhận lỗi misleading ("No questions passed validation"). Phát hiện qua test trên thiết bị thật với PDF thật (quota free-tier = 20 req/day/model) | High (reliability + cost-abuse signal) | Gemini provider: throttle 3s/call + serialize qua asyncio lock; validation gộp batch 5 câu/call (giảm ~2/3 số LLM call); LLMException từ batch judge **propagate** → exam fail với đúng nguyên nhân thay vì drop câu hỏi. 32/32 backend tests pass |
| A10 | **Crash 500 khi log tên file tiếng Việt** trên Windows: stdout redirect dùng cp1252 → `OSError: [Errno 22]` trong structlog PrintLogger → upload endpoint fail giữa chừng, lại tạo orphan record (đã commit DB trước khi log) | **High** (mất toàn bộ upload PDF Việt ngữ trên Windows dev machine) | `setup_logging` reconfigure stdout/stderr sang UTF-8 (errors=replace). Verified: upload lại đúng file "10 đề trắc nghiệm…PDF" thành công trên thiết bị thật |

**Secrets scan result:** SẠCH.
- `backend/.env` (chứa Gemini key thật) chưa từng xuất hiện trong bất kỳ git object/commit nào (quét toàn bộ `rev-list --all --objects`).
- Không có pattern `AIza…`, `sk-…`, private key trong tracked files hay history.
- Flutter code không chứa API key; `API_BASE_URL` là URL local dev (không phải secret) và tới từ `--dart-define`.
- `.gitignore` có `.env` ngay từ đầu ✅.

## 2. Đã kiểm tra, KHÔNG có vấn đề

- **SQL injection**: 100% SQLAlchemy ORM parameterized; không có raw SQL/`text()` nào trong `app/`.
- **JWT verify**: decode với `algorithms=[HS256]` tường minh (không cho `none`), `exp` được jose tự validate; sai token → 401; không có token trong URL/query.
- **Ownership các route còn lại**: documents get/status/list, exams get/status, sessions answer/submit/result/review, stats — tất cả filter theo `user_id`.
- **LLM key không sang client**: `QuestionResponse` không chứa `correct_index`/`explanation`/`source_ref` (chỉ Review sau khi submit mới trả); test `Questions must not leak the correct answer` trong E2E.
- **Storage path**: tên file lưu disk do server sinh (uuid), không dùng filename client → không có path traversal khi ghi file.
- **Prompt injection từ PDF**: câu hỏi bắt buộc qua QuestionValidator + `source_reference` đối chiếu text gốc; output là JSON schema (Pydantic), không parse bằng string/regex.

## 3. Tồn tại còn lại — chấp nhận cho MVP, cần xử lý trước production

| # | Vấn đề | Rủi ro | Đề xuất |
|---|---|---|---|
| R1 | Rate limiter **in-memory, single-process** | Mất tác dụng khi chạy nhiều uvicorn worker / nhiều instance | Chuyển counter sang Redis khi scale |
| R2 | `client_ip` tin `X-Forwarded-For` header | Client gian mạo IP nếu không đứng sau reverse proxy cấu hình đúng | Chỉ trust header khi deploy sau nginx/managed LB |
| R3 | HTTP **cleartext** backend ↔ app (dev LAN) | Chặn JWT + nội dung đề giữa đường | HTTPS (Let's Encrypt / Tailscale) khi deploy thật |
| R4 | CORS `allow_origins=["*"]` khi development | Browser bên khác gọi API (mobile không bị ảnh hưởng) | Set origin cụ thể trong production env |
| R5 | PDF parser (pdfplumber) chạy **inline trong event loop process** với file 50MB | CPU-DoS: 1 file quái dị có thể kéo chậm cả server (zip-bomb PDF) | Chạy process pool + timeout cứng + giới hạn số page (VD 200) |
| R6 | `error_message` của pipeline (chứa `str(e)`) trả về client | Leakage chi tiết internal | Chỉ trả mã lỗi chung khi `ENVIRONMENT=production` |
| R7 | Anonymous auth: device_id tự khai → đánh cắp device_id = giả mạo được user (không có binding thiết bị thật) | Low với MVP | Phase 2: SafetyNet/Play Integrity hoặc email OTP |
| R8 | JWT hết hạn sau 7 ngày, **không có refresh/revoke**; logout phía server không tồn tại | Token bị lấy trộm dùng tới hết hạn | Thuộc short-lived + refresh, hoặc denylist khi scale |
| R9 | Body-size guard chỉ dựa `Content-Length` (client nói dối được) | Bypass 413 → nhưng upload route đã cap khi đọc stream; JSON route không cap khi stream | Thêm `max_body_size` ở uvicorn/haproxy layer |
| R10 | Schema tạo bằng `create_all`, alembic chưa có migration thực tế | Drift schema khi lên production | Sinh baseline alembic migration |
| R11 | Không có giới hạn số document/exam mỗi user | Lãng phí disk + LLM cost | Thêm quota theo user |
| R12 | Mobile: sqflite cache chứa nội dung đề trên máy — thiết bị root đọc được | Low (chính dữ liệu của user đó) | Acceptable; cân nhắc encrypt DB nếu cần |
| R13 | Free-tier Gemini key chỉ **20 request/NGÀY/model** (quotaId `GenerateRequestsPerDayPerModel-FreeTier`; `retryDelay` trả về vài chục giây là **gây nhiễu**, không phải per-minute). Một đề ~9-13 call sau khi tối ưu → tối đa ~1-2 đề/ngày với key free. | High khi demo nhiều | Bật billing plan, hoặc chờ reset 00:00 UTC; thêm hard cap số exam/ngày/user phía server khi có billing |

## 4. Definition of Done — security (MAP vào AGENT.md mục 8)

- [x] Không hardcoded secrets trong source/frontend/git (scan tự động, 29/29 backend tests pass trong đó 12 security tests)
- [x] Auth route chống brute force (5/15')
- [x] Upload: MIME + magic bytes + size cap + filename sanitize
- [x] Mọi input có schema validation (Pydantic v2), payload lớn bị 413
- [x] Ownership (IDOR) test cho document + exam + session
- [ ] APK release: verify không chứa key (apktool — làm ở M6)
- [ ] HTTPS + CORS + Redis limiter (production checklist — R1/R2/R3/R4)
