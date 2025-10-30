---
name: pr-formatting
description: Format pull request descriptions with clear structure and comprehensive information. Use when creating PR descriptions, updating PR bodies, or helping users write effective pull requests for code review.
---

# Pull Request Formatting Best Practices

## Core Principles

A great PR description enables reviewers to:
1. **Understand context** - Why this change is needed
2. **Assess changes** - What was modified and how
3. **Verify correctness** - How to test and validate
4. **Deploy safely** - What considerations exist for production

## IMPORTANT: Check for Repository PR Template First

**Before using the standard structure below, always check for a PR template in the repository:**

```bash
# Common PR template locations
.github/PULL_REQUEST_TEMPLATE.md
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE
.github/PULL_REQUEST_TEMPLATE/default.md
docs/PULL_REQUEST_TEMPLATE.md
```

**If a PR template exists:**
- **Follow the template structure exactly**
- Fill in all sections the template requires
- Maintain any special formatting, checkboxes, or sections
- Preserve any instructions or comments in the template
- DO NOT deviate from the template format

**If no PR template exists:**
- Use the standard PR structure and best practices provided below
- Adapt to the team's style by reviewing recent PRs

**How to check:**
```bash
# Look for PR template
ls -la .github/PULL_REQUEST_TEMPLATE* .github/pull_request_template* 2>/dev/null

# If found, read it
cat .github/PULL_REQUEST_TEMPLATE.md
```

**Priority Order:**
1. **Existing PR template** (if found) - ALWAYS use this first
2. **Standard structure below** (if no template) - Use as fallback
3. **Team conventions** (review recent PRs) - Adapt style to match

## Standard PR Structure

**Use this structure ONLY if no repository PR template exists.**

### Title
- **Format**: `<Type>: <Clear description of change>`
- **Length**: Aim for 50-70 characters
- **Style**: Sentence case, no period at end
- **Action-oriented**: Start with verb (Add, Fix, Update, Refactor, etc.)

**Examples:**
- `Add OAuth2 authentication with Google provider`
- `Fix race condition in payment processing`
- `Refactor user validation into reusable middleware`
- `Update database schema for multi-tenancy support`

### Description Template

```markdown
## Summary
[2-4 sentences explaining what changed and why]
- High-level overview of the changes
- Business context or problem being solved
- Link to relevant issue, design doc, or discussion

## Changes
### [Component/Area 1]
- Specific change made
- Another change in this area

### [Component/Area 2]
- Changes in different area
- Keep grouped by logical component

## Testing
- [ ] Unit tests pass locally
- [ ] Integration tests pass
- [ ] Manual testing completed for [scenario]
- [ ] Edge cases verified: [list specific cases]
- [ ] Performance impact assessed

## Deployment Notes
**Database Changes:** [Yes/No - if yes, describe migrations]
**Breaking Changes:** [Yes/No - if yes, list what breaks]
**Feature Flags:** [List any feature flags or config changes needed]
**Rollback Plan:** [How to safely rollback if issues arise]

## Screenshots/Videos
[If UI changes, include before/after screenshots or demo video]

## Related Links
- Fixes #[issue-number]
- Related to #[issue-number]
- Design doc: [link]
- Previous PR: #[pr-number]
```

## Section Breakdown

### Summary Section
**Purpose**: Give reviewers immediate context without reading code

**Include:**
- **The "why"**: Business problem or technical need
- **The "what"**: High-level approach taken
- **The "impact"**: Who benefits and how

**Example:**
```markdown
## Summary
Adds OAuth2 authentication to support enterprise SSO requirements. Users can now sign in
with their company Google accounts instead of creating separate credentials. This change
implements the OAuth2 flow, token management, and session persistence required for
secure third-party authentication.

Closes #234 - Implements design from [SSO Architecture Doc](link)
```

### Changes Section
**Purpose**: Provide navigable overview of modifications

**Structure by component:**
```markdown
## Changes

### Authentication Service
- Add OAuth2Provider interface for pluggable providers
- Implement GoogleOAuthProvider with token exchange
- Add automatic token refresh logic with 5-minute buffer

### Database Schema
- New `oauth_tokens` table for storing refresh tokens
- Add `auth_provider` column to `users` table
- Migration script for existing users (sets to 'local')

### API Endpoints
- POST /auth/oauth/google/initiate - Start OAuth flow
- GET /auth/oauth/google/callback - Handle provider redirect
- POST /auth/oauth/refresh - Refresh expired tokens

### Configuration
- Add GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET env vars
- Update .env.example with new required variables
```

**Best practices:**
- Use bullet points for scannability
- Group by logical area, not by file
- Be specific but concise
- Link to complex files if needed: `See detailed logic in [auth.service.ts:L45-L89](link)`

### Testing Section
**Purpose**: Enable reviewers to verify changes and build confidence

**Be specific:**
```markdown
## Testing

### Automated Tests
- [ ] All unit tests pass (`npm test`)
- [ ] Integration tests pass (`npm run test:integration`)
- [ ] New tests added for OAuth flow (95% coverage on new code)

### Manual Testing
- [ ] Tested Google OAuth login flow end-to-end
- [ ] Verified token refresh works after expiration
- [ ] Confirmed session persistence across browser restarts
- [ ] Tested error handling for invalid OAuth responses

### Edge Cases Verified
- [ ] User cancels OAuth consent screen → shows appropriate error
- [ ] Token refresh fails → user redirected to re-authenticate
- [ ] Existing local-auth users unaffected by changes
- [ ] Multiple simultaneous OAuth requests handled correctly

### Performance
- OAuth login adds ~300ms compared to local auth (acceptable for UX trade-off)
- Token refresh is async and doesn't block requests
```

### Deployment Notes Section
**Purpose**: Prevent production issues and enable safe rollout

**Critical information:**
```markdown
## Deployment Notes

### Database Changes
**YES** - Requires running migration before deployment:
```bash
npm run migrate:up 20240115_add_oauth_support
```
Migration is non-destructive and backward-compatible.

### Breaking Changes
**NO** - Fully backward compatible. Existing local authentication continues to work.

### Configuration Required
Add to production environment variables:
- `GOOGLE_CLIENT_ID` (from Google Cloud Console)
- `GOOGLE_CLIENT_SECRET` (from Google Cloud Console)
- `OAUTH_REDIRECT_URI` (should be `https://yourdomain.com/auth/oauth/google/callback`)

### Feature Flags
- `ENABLE_OAUTH_GOOGLE` - Default: false (toggle to enable in production)
- Recommend enabling for internal team first, then gradual rollout

### Rollback Plan
1. Set `ENABLE_OAUTH_GOOGLE=false` to disable new flow
2. Existing sessions remain valid
3. If database rollback needed: `npm run migrate:down 20240115_add_oauth_support`

### Monitoring
Watch for:
- OAuth callback failures (should be <1%)
- Token refresh errors (indicates potential config issues)
- Login duration metrics (baseline: 300ms)
```

## PR Description Anti-Patterns

### ❌ Too Vague
```markdown
## Summary
Updated authentication system

## Changes
- Modified some files
- Fixed bugs
```
**Problem**: No context, no specifics, reviewer can't understand impact

### ❌ Too Verbose
```markdown
## Summary
In this pull request, I have implemented a comprehensive authentication system
that leverages the OAuth2 protocol specification as defined in RFC 6749. The
implementation began by first researching various OAuth providers and ultimately
settling on Google due to their robust documentation and widespread adoption...
[continues for 10 more paragraphs]
```
**Problem**: Loses reader, buries important details, reads like a diary

### ❌ Code-Focused Instead of Intent-Focused
```markdown
## Changes
- Modified auth.service.ts on lines 45-89
- Updated user.model.ts to add new fields
- Changed auth.controller.ts method signatures
- Refactored token.util.ts helper functions
```
**Problem**: Describes files changed (which git diff shows), not the purpose

### ❌ Missing Critical Information
```markdown
## Summary
Adds OAuth support

## Changes
- Implemented OAuth flow
- Added new database fields
```
[No testing, deployment notes, or configuration information]

**Problem**: Reviewer doesn't know how to test, deploy will likely fail

## Adaptive Formatting

### Small PRs (< 50 lines)
Keep it simple:
```markdown
## Summary
Fix typo in error message causing confusion for users when password reset fails.

## Changes
- Corrected "Passowrd" → "Password" in auth error message

## Testing
- Verified error displays correctly in UI
```

### Large PRs (> 500 lines)
Add navigation aids:
```markdown
## Summary
[Concise overview]

## Changes Overview
This PR touches 4 main areas:
1. **Authentication Service** - Core OAuth logic
2. **Database Schema** - Token storage
3. **API Layer** - New endpoints
4. **Frontend** - OAuth buttons and flows

Detailed breakdown below ⬇️

### 1. Authentication Service
[Details...]

### 2. Database Schema
[Details...]

[etc.]
```

### Feature PRs
Emphasize user impact:
```markdown
## Summary
**User Impact**: Enterprise customers can now use SSO, reducing onboarding friction

[Rest of PR description]

## User-Facing Changes
- New "Sign in with Google" button on login page
- OAuth consent screen (one-time)
- Automatic session management
```

### Bug Fix PRs
Emphasize the problem and solution:
```markdown
## Summary
**Bug**: Payment processing fails when users click "Pay" multiple times rapidly
**Impact**: 2.3% of transactions affected (last 30 days)
**Root Cause**: Race condition in payment state management
**Solution**: Introduce request-level locking with 30s timeout

## Reproduction Steps (Before Fix)
1. Load checkout page
2. Click "Pay Now" button rapidly 5+ times
3. Observe multiple charge attempts in payment logs

## How Fix Works
[Technical explanation]

## Testing
- [ ] Cannot reproduce bug after fix (tested 100+ attempts)
- [ ] Added integration test simulating rapid clicks
- [ ] Verified single charge still processes normally
```

## Context-Aware Descriptions

### PR Template Priority
As noted earlier, **always check for and follow repository PR templates first** (see "Check for Repository PR Template First" section above). Only use the guidelines below if no template exists.

### Match Team Style
Review recent PRs to match:
- Level of detail expected
- Section names and order
- Emoji usage (some teams use 🎯, 🧪, 🚀, etc.)
- Tone (formal vs. casual)

### Adjust for Audience
- **External contributors**: More context, more links, explain project conventions
- **Internal team**: Can assume knowledge, focus on specifics
- **Security PRs**: May need less detail in public description

## Checklist Before Publishing

- [ ] Checked for repository PR template and followed it (if exists)
- [ ] Title clearly describes the change
- [ ] Summary explains WHY (not just what)
- [ ] Changes section is scannable and specific
- [ ] Testing instructions are clear and complete
- [ ] Deployment requirements documented
- [ ] Breaking changes clearly marked
- [ ] Related issues/PRs linked
- [ ] Screenshots included for UI changes
- [ ] No sensitive information (secrets, internal URLs, etc.)

## Remember

A well-written PR description:
- **Saves reviewer time** → faster approvals
- **Reduces back-and-forth** → fewer clarification questions
- **Prevents deployment issues** → clear requirements documented
- **Serves as documentation** → useful historical reference

Invest 10 minutes in a great PR description to save hours in review cycles.
