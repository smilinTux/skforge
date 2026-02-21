# SKForge Blueprint: PDF Automation

> Universal blueprint for AI-powered PDF form filling and document management.

## Overview

This blueprint defines the architecture for intelligent PDF processing
systems that extract form fields, auto-fill from user profiles, handle
missing data conversationally, and file completed documents using GTD
(Getting Things Done) organizational principles.

## Core Concepts

### Form Session Lifecycle

```
PDF Input → Field Extraction → Field Mapping → Auto-Fill
  → Question Engine (missing fields) → PDF Writing → GTD Filing
```

### Field Types

| Type | Detection | Fill Method |
|------|----------|-------------|
| **AcroForm** | pikepdf field reader | Direct value write |
| **XFA** | XML parser | XFA value injection |
| **OCR-detected** | Tesseract + position analysis | Overlay text/checkbox |
| **Template-matched** | Fingerprint lookup | Pre-mapped fill |

### GTD Filing Model

```
@Inbox      → Unprocessed documents
@Action     → Needs follow-up (send, sign, review)
  ├── Next-Actions/
  └── Waiting-For/
@Reference  → Filed for future access (categorized by type + year)
@Projects   → Active multi-document projects
@Archive    → Completed, rarely accessed
```

### Profile Integration

PDF fields map to structured profile data paths:
- `identity.full_name` → "Patient Name", "Full Name", "Applicant"
- `contact.address.street` → "Address", "Street Address", "Mailing Address"
- `medical.insurance_provider` → "Insurance Company", "Provider"

Field mapping uses: exact match → fuzzy match → LLM-assisted mapping.

---

## Configuration Model

```yaml
profile:
  source: "capauth"
  sensitive_require_approval: true

extraction:
  methods: ["acroform", "xfa", "ocr"]
  ocr_engine: "tesseract"
  ocr_dpi: 300

filing:
  gtd_root: "~/Documents"
  naming: "{date}_{description}_{source}"
  auto_categorize: true
  metadata_sidecars: true
  destinations: ["local", "nextcloud"]
```

---

## Security Model

| Concern | Mitigation |
|---------|-----------|
| PII exposure | Sensitive fields gated by AI advocate |
| Unauthorized forms | Source verification via CapAuth |
| Data at rest | Filed PDFs encrypted (optional) |
| Audit trail | Every field fill logged with source |

---

## Extension Points

- **Template contributions** — community-submitted form mappings
- **Filing backends** — local, Nextcloud, Google Drive, Dropbox, IPFS
- **Chat integrations** — SKChat, Matrix, XMPP bots
- **OCR engines** — Tesseract, EasyOCR, PaddleOCR
- **LLM field mapping** — local or remote model for ambiguous fields
