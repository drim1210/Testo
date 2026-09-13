# Testo REST API Specification

All endpoints are prefixed with `/api/v1`. Authentication uses standard HTTP Bearer Tokens (`Authorization: Bearer <jwt_token>`).

---

## 1. Authentication (`/api/v1/auth`)

### POST `/api/v1/auth/anonymous`
Establishes or restores an anonymous device session.
* **Request Body**:
  ```json
  {
    "device_id": "string (UUID or persistent device identifier)"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "user_id": "36729571-70bf-4e76-a05e-85750fc878a8"
  }
  ```

---

## 2. Document Management (`/api/v1/documents`)

### POST `/api/v1/documents/upload`
Uploads a document for processing (PDF, Word DOCX).
* **Headers**: `Content-Type: multipart/form-data`, `Authorization: Bearer <token>`
* **Form-data**: `file: <binary content>`
* **Response (201 Created)**:
  ```json
  {
    "id": "doc-uuid",
    "filename": "Tài liệu ôn tập.docx",
    "status": "uploaded",
    "created_at": "2026-09-14T00:00:00Z"
  }
  ```

### GET `/api/v1/documents/{doc_id}/status`
Polls background extraction status.
* **Response (200 OK)**:
  ```json
  {
    "id": "doc-uuid",
    "status": "ready", // uploaded | processing | ready | failed
    "error_message": null
  }
  ```

---

## 3. Exam Orchestration (`/api/v1/exams`)

### POST `/api/v1/exams/`
Triggers AI pipeline to generate an exam.
* **Request Body**:
  ```json
  {
    "document_id": "doc-uuid",
    "config": {
      "num_questions": 10,
      "difficulty": "mixed", // easy | medium | hard | mixed
      "question_type": "mcq",
      "focus_important": true
    }
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "exam_id": "exam-uuid",
    "status": "generating"
  }
  ```

### GET `/api/v1/exams/{exam_id}/status`
Real-time generation progress updates.
* **Response (200 OK)**:
  ```json
  {
    "id": "exam-uuid",
    "status": "ready", // generating | ready | failed
    "progress_step": 6,
    "progress_message": "Exam ready with 10 questions",
    "error_message": null
  }
  ```

### GET `/api/v1/exams/{exam_id}`
Retrieves questions for taking the exam (answers are masked until submission).
* **Response (200 OK)**:
  ```json
  {
    "id": "exam-uuid",
    "title": "Exam from Tài liệu ôn tập.docx",
    "questions": [
      {
        "id": "q-uuid-1",
        "content": "Pha sáng của quang hợp diễn ra ở đâu?",
        "options": ["Trên màng thylakoid", "Trong stroma", "Trong tế bào chất", "Tại ty thể"],
        "order_index": 0,
        "topic": "Quang hợp",
        "difficulty": "easy"
      }
    ]
  }
  ```

---

## 4. Exam Sessions & Analytics (`/api/v1/sessions`, `/api/v1/stats`)

### POST `/api/v1/sessions/{exam_id}/start` -> Start session timer
### PATCH `/api/v1/sessions/{session_id}/answer` -> Submit answer for question
### PATCH `/api/v1/sessions/{session_id}/bookmark` -> Toggle question bookmark
### POST `/api/v1/sessions/{session_id}/submit` -> Grade session, compute topic scores
### GET `/api/v1/sessions/{session_id}/review` -> Comprehensive review with explanations and source citations
### GET `/api/v1/stats/overview` -> Total exams, average score, best score
### GET `/api/v1/stats/topics` -> Topic mastery percentage breakdown
