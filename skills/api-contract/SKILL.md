---
name: api-contract
description: |
  Defines and documents API contracts between frontend and backend.
  Use when: creating new endpoints, updating existing APIs, documenting integration points,
  generating TypeScript types from Rails serializers, or verifying API alignment.
---

# API Contract Definition

This skill teaches how to define and document API contracts between the ProcurementExpress frontend and backend.

## Standard Contract Format

```markdown
## Endpoint: [Resource Name]

### [METHOD] /api/v1/[path]

**Authentication:**
- authentication_token: required (header)
- app_company_id: required (header)

**Request Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | yes | Resource name |
| page | integer | no | Page number for pagination |
| per_page | integer | no | Items per page (10, 20, 50, 100) |

**Request Body:** (for POST/PUT)
```json
{
  "resource": {
    "name": "string",
    "description": "string"
  }
}
```

**Response (200):**
```json
{
  "id": 1,
  "name": "Resource Name",
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Paginated Response:**
```json
{
  "resources": [...],
  "meta": {
    "current_page": 1,
    "next_page": 2,
    "prev_page": null,
    "total_pages": 10,
    "total_count": 100
  }
}
```

**Error Responses:**
- 401: `{ "error": "Unauthorized", "status": 401 }`
- 404: `{ "error": "Not found", "status": 404 }`
- 422: `{ "errors": { "field": ["message"] } }`
```

## TypeScript Type Mapping

Map Rails serializer attributes to TypeScript interfaces:

| Rails Type | TypeScript Type | Notes |
|------------|-----------------|-------|
| `string` | `string` | |
| `integer` | `number` | |
| `float`/`decimal` | `number` | |
| `boolean` | `boolean` | |
| `datetime` | `string` | ISO 8601 format |
| `date` | `string` | YYYY-MM-DD format |
| `text` | `string` | |
| `json`/`jsonb` | `Record<string, unknown>` | Or specific interface |
| `has_many :items` | `items: Item[]` | Array of related type |
| `belongs_to :parent` | `parent: Parent \| null` | Nullable if optional |
| `has_one :detail` | `detail: Detail \| null` | Nullable if optional |

## Example: Rails Serializer to TypeScript

**Rails Serializer:**
```ruby
class PolicySerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status, :version, :created_at, :updated_at

  has_many :rules, serializer: PolicyRuleSerializer
  belongs_to :created_by, serializer: UserSerializer

  def created_at
    object.created_at.iso8601
  end
end
```

**TypeScript Interface:**
```typescript
interface Policy {
  id: number;
  name: string;
  description: string | null;
  status: 'draft' | 'active' | 'archived';
  version: number;
  created_at: string;
  updated_at: string;
  rules: PolicyRule[];
  created_by: User | null;
}
```

## Validation Rules

When documenting API contracts:

1. **Always include authentication** - All endpoints require `authentication_token` and `app_company_id`
2. **Document all response codes** - 200, 201, 401, 404, 422, 500
3. **Use ISO 8601 for dates** - Backend serializers should format with `.iso8601`
4. **Note nullable fields** - Mark optional/nullable fields in TypeScript
5. **Include pagination meta** - For list endpoints, always include meta structure

## Quick Reference: Common Patterns

**List Endpoint:**
```
GET /api/v1/resources?page=1&per_page=20&status=active
```

**Show Endpoint:**
```
GET /api/v1/resources/:id
```

**Create Endpoint:**
```
POST /api/v1/resources
Body: { "resource": { ... } }
```

**Update Endpoint:**
```
PUT /api/v1/resources/:id
Body: { "resource": { ... } }
```

**Delete Endpoint:**
```
DELETE /api/v1/resources/:id
```

**Custom Action:**
```
POST /api/v1/resources/:id/publish
```
