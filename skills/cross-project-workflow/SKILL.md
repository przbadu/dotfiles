---
name: cross-project-workflow
description: |
  Coordinates work between frontend (React/TypeScript) and backend (Rails) ProcurementExpress projects.
  Use when: implementing features that span both projects, understanding integration patterns,
  planning cross-project changes, checking if APIs exist, or coordinating frontend/backend work.
---

# Cross-Project Workflow

This skill teaches how to coordinate development between the ProcurementExpress frontend and backend projects.

## Project Paths

Read paths from `~/.claude/CLAUDE.md` under `pex_projects`:
- **Frontend**: React 19, TypeScript, Vite
- **Backend**: Rails 6.1.7.6, PostgreSQL

If paths are not configured, prompt the user to add them to `~/.claude/CLAUDE.md`.

## Workflow Rules

1. **Read First**: Always read the other project's code before suggesting changes
2. **API Contract Priority**: The API contract is the source of truth
3. **Permission Required**: Ask explicit permission before modifying the other project
4. **Follow Conventions**: Use each project's established patterns

## Integration Points

| Component | Frontend Location | Backend Location |
|-----------|------------------|------------------|
| API Calls | `services/*.ts` | `app/controllers/api/v1/` |
| Data Types | `types.ts` | `app/serializers/` |
| Data Models | N/A | `app/models/` |
| React Hooks | `hooks/queries/*.ts` | N/A |
| Routes | N/A | `config/routes.rb` |
| Auth | `contexts/AuthContext.tsx` | `app/controllers/api/v1/base_controller.rb` |

## Typical Workflow

### When Frontend Needs Backend API:

1. **Check if API exists**: Read `app/controllers/api/v1/{resource}_controller.rb`
2. **Check serializer**: Read `app/serializers/{resource}_serializer.rb`
3. **If API missing**: Request permission to create in backend
4. **Implement frontend**: Create service, types, and hooks

### When Backend API Changes:

1. **Find frontend usage**: Search `services/*.ts` for endpoint
2. **Check types**: Review `types.ts` for affected interfaces
3. **Report impact**: List all affected components
4. **Request permission**: Ask before updating frontend

## Permission Request Template

```markdown
## Cross-Project Modification Request

**Target Project:** [Frontend/Backend]
**Files to Modify:**
- `path/to/file`: description of change

**Reason:** [Why this change is needed]
**Impact:** [What this enables/fixes]

**May I proceed? (yes/no)**
```

## API Contract Format

When documenting API integration:

```markdown
## Endpoint: [Resource Name]

**Method:** GET/POST/PUT/DELETE
**Path:** /api/v1/[path]

**Headers:**
- authentication_token: required
- app_company_id: required

**Request Body:** (if applicable)
```json
{ ... }
```

**Response:**
```json
{ ... }
```

**Frontend Service:** `services/{resource}Service.ts`
**Frontend Types:** `types.ts` - `interface {Resource}`
```
