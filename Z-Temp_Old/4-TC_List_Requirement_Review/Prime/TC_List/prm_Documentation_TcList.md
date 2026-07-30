# Documentation (Categories + Articles) — Test Case List

**Feature:** Platform Documentation Management | **REQ-ID:** REQ-PRM-DOC | **Controllers:** `DocumentationController`, `DocumentationCategoryController`, `DocumentationArticleController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 56 | — | — | — | 56 | 0% |

---

## 2. Category Index/List (`GET /prime/documentation-categories`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-001 | Verify category list loads with pagination (10/page) | Authenticated user with categories in DB | — | 10 records per page, ordered by `latest()` | — | — | ⬜ |
| TC-PRM-DOC-002 | Verify search by `name` filters results | Categories with varying names | `search=getting` | Only categories with `getting` in name displayed | — | — | ⬜ |
| TC-PRM-DOC-003 | Verify `type` filter works | Categories of different types | `type=blog` | Only blog-type categories displayed | — | — | ⬜ |
| TC-PRM-DOC-004 | Verify `status` (is_active) filter works | Active + inactive categories | `status=0` | Only inactive categories displayed | — | — | ⬜ |
| TC-PRM-DOC-005 | Verify parent category name shown in list | Category with `parent_id` set | — | Parent name column populated correctly | — | — | ⬜ |
| TC-PRM-DOC-006 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login page | — | — | ⬜ |
| TC-PRM-DOC-007 | Verify pagination query string preserved with search/filter | 15+ categories | `?search=test&page=2` | Page 2 loads with search param preserved | — | — | ⬜ |

---

## 3. Category Create (`GET /prime/documentation-categories/create` + `POST /prime/documentation-categories`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-008 | Verify create form loads with parent dropdown | Root categories exist | — | Form renders with parent select, type select, name input | — | — | ⬜ |
| TC-PRM-DOC-009 | Verify store with valid data succeeds | Authenticated with create permission | `{name: "Getting Started", type: "documentation"}` | 302 redirect to documentation-mgt; record created; audit logged | — | — | ⬜ |
| TC-PRM-DOC-010 | Verify store with duplicate name rejected | Category `Getting Started` exists | `{name: "Getting Started"}` | 422 validation error: name already taken | — | — | ⬜ |
| TC-PRM-DOC-011 | Verify store with invalid type rejected | — | `{name: "Test", type: "invalid"}` | 422 validation error: invalid type | — | — | ⬜ |
| TC-PRM-DOC-012 | Verify store with parent_id set creates child category | Root category ID=1 | `{name: "Child", parent_id: 1}` | Category created with correct parent_id | — | — | ⬜ |
| TC-PRM-DOC-013 | Verify store with self as parent_id rejected | Category being created | `{name: "Test", parent_id: current_id}` | ⚠️ Not applicable for create (no self-reference on create) | — | — | ⬜ |
| TC-PRM-DOC-014 | Verify store with non-existent parent_id rejected | — | `{name: "Test", parent_id: 9999}` | 422 validation error: parent_id must exist | — | — | ⬜ |
| TC-PRM-DOC-015 | Verify store auto-generates slug from name | — | `{name: "My Category"}` | Slug set to `my-category` in DB | — | — | ⬜ |
| TC-PRM-DOC-016 | Verify store with featured image upload succeeds | Valid image file | Image file + valid data | Image stored in `doc_category_image` media collection | — | — | ⬜ |
| TC-PRM-DOC-017 | Verify store with `sort_order` value (after model fix) | — | `{name: "Test", sort_order: 5}` | sort_order = 5 stored in DB | — | — | ⬜ |
| TC-PRM-DOC-018 | Verify store with `sort_order` value (current bug) | — | `{name: "Test", sort_order: 5}` | ⚠️ sort_order silently dropped (not in $fillable) | — | — | ⬜ |
| TC-PRM-DOC-019 | Verify unauthenticated user redirected on store POST | No session | Valid data | Redirected to login | — | — | ⬜ |

---

## 4. Category Edit/Update (`GET /prime/documentation-categories/{id}/edit` + `PUT /prime/documentation-categories/{id}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-020 | Verify edit form loads for valid category ID | Category ID=1 exists | — | Form renders with current values pre-filled; parent dropdown excludes self | — | — | ⬜ |
| TC-PRM-DOC-021 | Verify edit form for non-existent ID returns 404 | No category ID=9999 | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-DOC-022 | Verify update changes name and slug | Category ID=1, name=`Old` | `{name: "New Name"}` | Name updated; slug regenerated to `new-name`; audit logged with changes | — | — | ⬜ |
| TC-PRM-DOC-023 | Verify update with duplicate name rejected | Another category has same name | `{name: "existing-name"}` | 422 validation error | — | — | ⬜ |
| TC-PRM-DOC-024 | Verify update changes parent_id | Category ID=2, new parent ID=1 | `{parent_id: 1}` | parent_id updated to 1 | — | — | ⬜ |
| TC-PRM-DOC-025 | Verify update rejects self as parent | Category ID=1 | `{parent_id: 1}` | 422 validation error: cannot be own parent | — | — | ⬜ |
| TC-PRM-DOC-026 | Verify update replaces featured image | Category with existing image | New image file | Old image cleared; new image stored | — | — | ⬜ |

---

## 5. Category Status Toggle (`POST /prime/documentation-categories/{id}/toggle-status`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-027 | Verify toggleStatus activates inactive category | Category is_active=false | `{is_active: true}` | JSON `{success:true, is_active:true}`; DB column updated | — | — | ⬜ |
| TC-PRM-DOC-028 | Verify toggleStatus deactivates active category | Category is_active=true | `{is_active: false}` | JSON `{success:true, is_active:false}`; DB column updated | — | — | ⬜ |
| TC-PRM-DOC-029 | Verify toggleStatus with invalid boolean rejected | — | `{is_active: "yes"}` | 422 validation error | — | — | ⬜ |

---

## 6. Category Soft Delete / Trash / Restore / Force Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-030 | Verify DELETE soft-deletes category | Active category ID=1 | — | `deleted_at` set; `is_active=false`; redirect to index with trashed flash | — | — | ⬜ |
| TC-PRM-DOC-031 | Verify trashed view shows only deleted categories | Deleted + active categories exist | — | Only soft-deleted categories listed with restore/force-delete buttons | — | — | ⬜ |
| TC-PRM-DOC-032 | Verify restore brings category back | Deleted category ID=1 | — | `deleted_at` cleared; redirect to trash view | — | — | ⬜ |
| TC-PRM-DOC-033 | Verify force delete permanently removes category | Deleted category with no children | — | Record removed from DB; redirect to trash with success flash | — | — | ⬜ |
| TC-PRM-DOC-034 | Verify force delete of category with children fails | Parent category has child categories | — | FK RESTRICT blocks deletion; error flash shown | — | — | ⬜ |
| TC-PRM-DOC-035 | Verify force delete exception returns error flash | Category with DB constraint violation | — | Redirect with `flash('operation_failed.documentation_category')` | — | — | ⬜ |

---

## 7. Article Index/List (`GET /prime/documentation-articles`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-036 | Verify article list loads with pagination (10/page) | Authenticated user with articles | — | 10 records per page, `latest()` ordering | — | — | ⬜ |
| TC-PRM-DOC-037 | Verify search by `title` filters results | Articles with varying titles | `search=guide` | Only articles with `guide` in title displayed | — | — | ⬜ |
| TC-PRM-DOC-038 | Verify `type` filter on articles works | Articles of different types | `type=help` | Only help-type articles displayed | — | — | ⬜ |
| TC-PRM-DOC-039 | Verify `status` (is_published) filter works | Published + unpublished articles | `status=0` | Only unpublished articles displayed | — | — | ⬜ |
| TC-PRM-DOC-040 | Verify category names shown in article list | Article assigned to categories | — | Category badges/names displayed for each article | — | — | ⬜ |
| TC-PRM-DOC-041 | Verify author name shown in article list | Article with `created_by` set | — | Author name displayed | — | — | ⬜ |

---

## 8. Article Create (`GET /prime/documentation-articles/create` + `POST /prime/documentation-articles`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-042 | Verify create form loads with category multi-select | Active categories exist | — | Form renders with categories checkboxes/select, Summernote editor | — | — | ⬜ |
| TC-PRM-DOC-043 | Verify store with valid data creates article | Authenticated with create permission | `{title: "Guide", type: "documentation", content: "<p>Hello</p>", visibility: "public"}` | 302 redirect; article created; audit logged | — | — | ⬜ |
| TC-PRM-DOC-044 | Verify store with `category_ids` creates junction records | Categories ID 1,2 | `{..., category_ids: [1,2]}` | 2 records in `doc_article_category_jnt` | — | — | ⬜ |
| TC-PRM-DOC-045 | Verify store with `categories[]` form field (current bug) | Categories exist | `{..., categories: [1,2]}` (form field name mismatch) | ⚠️ Category sync silently fails — no junction records | — | — | ⬜ |
| TC-PRM-DOC-046 | Verify store with duplicate title rejected | Article `Guide` exists | `{title: "Guide"}` | 422 validation error: title already taken | — | — | ⬜ |
| TC-PRM-DOC-047 | Verify store with invalid visibility rejected | — | `{visibility: "secret"}` | 422 validation error | — | — | ⬜ |
| TC-PRM-DOC-048 | Verify store auto-generates slug from title | — | `{title: "Getting Started"}` | Slug set to `getting-started` | — | — | ⬜ |
| TC-PRM-DOC-049 | Verify store with featured image upload | Valid image file | Image + valid data | Image stored in `doc_article_image` collection | — | — | ⬜ |
| TC-PRM-DOC-050 | Verify store sets `created_by` to authenticated user | Auth user ID=1 | Valid data | `created_by` = 1 in DB | — | — | ⬜ |
| TC-PRM-DOC-051 | Verify store with `published_at` in future | — | `{published_at: next_year}` | Article created with future date; hidden from `scopePublished()` | — | — | ⬜ |

---

## 9. Article Edit/Update (`GET /prime/documentation-articles/{id}/edit` + `PUT /prime/documentation-articles/{id}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-052 | Verify edit form loads with pre-filled values | Article ID=1 with category assignment | — | Form has current title, content (Summernote), categories selected | — | — | ⬜ |
| TC-PRM-DOC-053 | Verify update modifies title and regenerates slug | Article ID=1 | `{title: "Updated Title"}` | Title changed; slug becomes `updated-title`; audit has field-level changes | — | — | ⬜ |
| TC-PRM-DOC-054 | Verify update changes category assignment | Article ID=1, new categories [3] | `{..., category_ids: [3]}` | Junction table has only category_id=3 for article | — | — | ⬜ |
| TC-PRM-DOC-055 | Verify update with empty `category_ids` clears all categories | Article previously assigned to [1,2] | `{category_ids: []}` (or omitted) | Junction table empty for article (via `sync([])`) | — | — | ⬜ |
| TC-PRM-DOC-056 | Verify update replaces featured image | Article with existing image | New image | Old image cleared; new image stored | — | — | ⬜ |

---

## 10. Article Status Toggle (`POST /prime/documentation-articles/{id}/toggle-status`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-057 | Verify toggleStatus publishes unpublished article | Article is_published=false | `{is_published: true}` | JSON `{success:true, is_published:true}`; DB updated | — | — | ⬜ |
| TC-PRM-DOC-058 | Verify toggleStatus unpublishes published article | Article is_published=true | `{is_published: false}` | JSON `{success:true, is_published:false}`; DB updated | — | — | ⬜ |

---

## 11. Article Soft Delete / Trash / Restore / Force Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-059 | Verify DELETE soft-deletes article | Active article ID=1 | — | `deleted_at` set; `is_published=false`; redirect | — | — | ⬜ |
| TC-PRM-DOC-060 | Verify article trashed view shows deleted articles | Deleted articles exist | — | Only soft-deleted articles listed; categories + author loaded | — | — | ⬜ |
| TC-PRM-DOC-061 | Verify restore brings back article | Deleted article ID=1 | — | `deleted_at` cleared; redirect to trash | — | — | ⬜ |
| TC-PRM-DOC-062 | Verify force delete permanently removes article | Deleted article ID=1 | — | Record removed from DB; success flash | — | — | ⬜ |
| TC-PRM-DOC-063 | Verify force delete exception returns error flash | Article with DB constraint | — | Error flash; stays in trash | — | — | ⬜ |

---

## 12. Documentation Management Hub (`GET /prime/documentation-mgt`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-064 | Verify management hub loads with both tabs | Categories + articles exist | — | View has Categories tab and Articles tab with respective lists | — | — | ⬜ |
| TC-PRM-DOC-065 | Verify search on management hub filters both tabs | — | `search=guide` | Both category and article results filtered | — | — | ⬜ |
| TC-PRM-DOC-066 | Verify type filter on hub works | Mixed content | `type=blog` | Both tabs show only blog-type content | — | — | ⬜ |
| TC-PRM-DOC-067 | Verify unauthenticated user redirected | No session | — | Redirect to login | — | — | ⬜ |

---

## 13. Documentation Reader (`GET /prime/documentation-intro`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-068 | Verify reader loads 3-column layout | Root categories with active children and published articles | `?type=documentation` | Left sidebar: categories; Center: first article content; Right: article list | — | — | ⬜ |
| TC-PRM-DOC-069 | Verify reader defaults to `type=documentation` | No type param | — | Only documentation-type content shown | — | — | ⬜ |
| TC-PRM-DOC-070 | Verify reader filters by `?type=help` | Categories + articles of different types | `?type=help` | Only help-type categories and articles shown | — | — | ⬜ |
| TC-PRM-DOC-071 | Verify reader hides inactive categories | Category with `is_active=false` | — | Inactive category not shown in sidebar | — | — | ⬜ |
| TC-PRM-DOC-072 | Verify reader hides unpublished articles | Article with `is_published=false` | — | Unpublished article not shown in article list | — | — | ⬜ |
| TC-PRM-DOC-073 | Verify reader hides non-public articles | Article with `visibility=internal` | — | Internal article not shown | — | — | ⬜ |
| TC-PRM-DOC-074 | Verify reader excludes future-dated articles | Article with `published_at` in future | — | Future article hidden by `scopePublished()` | — | — | ⬜ |
| TC-PRM-DOC-075 | Verify auto-select first category and subcategory | Categories with hierarchy | — | First root category expanded; first child selected; articles loaded | — | — | ⬜ |

---

## 14. AJAX Get Articles by Category (`GET /prime/documentation/articles/{categoryId}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-076 | Verify AJAX returns articles for valid category ID | Category ID=1 with published articles | `categoryId=1` | JSON `{success:true, articles:[...]}` with id, title, content, excerpt, published_at, author_name | — | — | ⬜ |
| TC-PRM-DOC-077 | Verify AJAX returns empty for category with no articles | Category with no articles | `categoryId=2` | JSON `{success:true, articles:[]}` | — | — | ⬜ |
| TC-PRM-DOC-078 | Verify AJAX excludes unpublished articles | Article is_published=false | `categoryId=1` | Unpublished articles not in response | — | — | ⬜ |
| TC-PRM-DOC-079 | Verify AJAX excludes non-public articles | Article visibility=draft | `categoryId=1` | Draft articles not in response | — | — | ⬜ |
| TC-PRM-DOC-080 | Verify AJAX returns 500 error on exception | — | Invalid categoryId | JSON `{success:false, message:"Error loading articles", articles:[]}` | — | — | ⬜ |

---

## 15. Image Upload (`POST /prime/documentation/upload-image` and `/prime/documentation/articles/upload-image`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-081 | Verify category uploadImage stores file | Valid image | Image file | File stored at `documentation/summernote/`; returns URL string | — | — | ⬜ |
| TC-PRM-DOC-082 | Verify article uploadImage stores file | Valid image | Image file | File stored at `documentation/articles/summernote/`; returns URL string | — | — | ⬜ |
| TC-PRM-DOC-083 | Verify uploadImage rejects non-image file | Text file | `file.txt` | 422 validation error | — | — | ⬜ |
| TC-PRM-DOC-084 | Verify uploadImage rejects oversized file (current: 20 MB) | File over 20 MB | 21 MB file | 422 validation error: max 20048 KB | — | — | ⬜ |
| TC-PRM-DOC-085 | Verify uploadImage rejects SVG (security) | SVG file | `image.svg` | ⚠️ Currently NOT blocked — allowed by `image` rule | — | — | ⬜ |

---

## 16. Authorization & Security

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-086 | Verify user without `viewAny` gets 403 on article index | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-087 | Verify user without `viewAny` gets 403 on category trashed | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-088 | Verify user without `create` gets 403 on category create | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-089 | Verify user without `update` gets 403 on toggleStatus | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-090 | Verify user without `delete` gets 403 on destroy | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-091 | Verify user without `restore` gets 403 on restore | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-092 | Verify user without `forceDelete` gets 403 on forceDelete | Authenticated, no permission | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-DOC-093 | Verify category index MISSING Gate check — user without permission can still list | Authenticated, no permission | — | ⚠️ BUG: No Gate on index — user sees categories despite having no `viewAny` permission | — | — | ⬜ |
| TC-PRM-DOC-094 | Verify uploadImage MISSING Gate check — user without permission can upload | Authenticated, no permission | Image file | ⚠️ BUG: No Gate on uploadImage — unauthorized upload succeeds | — | — | ⬜ |
| TC-PRM-DOC-095 | Verify Gate string mismatch — singular vs plural bypasses authorization | Authenticated with no explicit permission | — | ⚠️ BUG: Controller uses singular Gate string; Policy registers plural — Gate check passes even though user has no permission | — | — | ⬜ |

---

## 17. Edge Cases

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-DOC-096 | Verify XSS prevention in article content | — | Article content: `<script>alert(1)</script>` | ⚠️ Raw HTML stored and rendered via `{!! !!}` — XSS executed | — | — | ⬜ |
| TC-PRM-DOC-097 | Verify XSS prevention in AJAX-loaded articles | Article with XSS content | Load via AJAX | ⚠️ `innerHTML` injection executes XSS | — | — | ⬜ |
| TC-PRM-DOC-098 | Verify category with 100+ children loads without memory issues | Root category with 100+ children | — | Page renders without timeout (potential N+1 via `childrenRecursive`) | — | — | ⬜ |
| TC-PRM-DOC-099 | Verify article with very long content (10k+ words) renders | Article with large content | — | Reader renders without timeout or layout breakage | — | — | ⬜ |
| TC-PRM-DOC-100 | Verify HTML injection in excerpt | Article with malicious excerpt | `Excerpt: <script>alert(1)</script>` | ⚠️ Potentially unsanitized if escaped in view | — | — | ⬜ |
| TC-PRM-DOC-101 | Verify `sort_order` display order in reader (after fix) | Articles with sort_order 1,2,3 | — | Articles displayed in ascending sort_order | — | — | ⬜ |
| TC-PRM-DOC-102 | Verify `canonical_url` validation rejects invalid URL | — | `canonical_url: "not-a-url"` | 422 validation error: must be valid URL | — | — | ⬜ |

---

## 18. Permissions Matrix

| Role | View Hub | View Reader | Categories: List/Create/Edit/Delete | Categories: Trash/Restore/ForceDel | Articles: List/Create/Edit/Delete | Articles: Trash/Restore/ForceDel | Upload Images |
|------|:--------:|:-----------:|:-----------------------------------:|:----------------------------------:|:---------------------------------:|:--------------------------------:|:-------------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Support | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| School Admin | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Teacher | ❌ | ✅ (public only) | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 19. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-DOC-001 | REQ-PRM-DOC | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-DOC-002 | REQ-PRM-DOC | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-DOC-003 | REQ-PRM-DOC | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-004 | REQ-PRM-DOC | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-005 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-006 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-007 | REQ-PRM-DOC | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-DOC-008 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-009 | REQ-PRM-DOC | BR-PRM-DOC-016 | Positive/Create | P0 | Functional | ⬜ |
| TC-PRM-DOC-010 | REQ-PRM-DOC | BR-PRM-DOC-002 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-011 | REQ-PRM-DOC | BR-PRM-DOC-005 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-012 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-014 | REQ-PRM-DOC | BR-PRM-DOC-002 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-015 | REQ-PRM-DOC | — | Positive/Logic | P2 | Functional | ⬜ |
| TC-PRM-DOC-016 | REQ-PRM-DOC | — | Positive/Media | P2 | Functional | ⬜ |
| TC-PRM-DOC-017 | REQ-PRM-DOC | BR-PRM-DOC-015 | Positive (after fix) | P1 | Functional | ⬜ |
| TC-PRM-DOC-018 | REQ-PRM-DOC | BR-PRM-DOC-015 | Regression/Bug | P1 | Functional | ⬜ |
| TC-PRM-DOC-019 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-020 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-021 | REQ-PRM-DOC | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-DOC-022 | REQ-PRM-DOC | BR-PRM-DOC-016 | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-023 | REQ-PRM-DOC | BR-PRM-DOC-002 | Negative | P1 | Functional | ⬜ |
| TC-PRM-DOC-024 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-025 | REQ-PRM-DOC | BR-PRM-DOC-001 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-026 | REQ-PRM-DOC | — | Positive/Media | P2 | Functional | ⬜ |
| TC-PRM-DOC-027 | REQ-PRM-DOC | — | Positive/AJAX | P1 | Functional | ⬜ |
| TC-PRM-DOC-028 | REQ-PRM-DOC | — | Positive/AJAX | P1 | Functional | ⬜ |
| TC-PRM-DOC-029 | REQ-PRM-DOC | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-030 | REQ-PRM-DOC | BR-PRM-DOC-011 | Positive/Delete | P1 | Functional | ⬜ |
| TC-PRM-DOC-031 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-032 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-033 | REQ-PRM-DOC | BR-PRM-DOC-014 | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-034 | REQ-PRM-DOC | BR-PRM-DOC-014 | Negative/Constraint | P1 | Functional | ⬜ |
| TC-PRM-DOC-035 | REQ-PRM-DOC | — | Negative/Exception | P2 | Functional | ⬜ |
| TC-PRM-DOC-036 | REQ-PRM-DOC | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-DOC-037 | REQ-PRM-DOC | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-DOC-038 | REQ-PRM-DOC | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-039 | REQ-PRM-DOC | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-040 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-041 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-042 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-043 | REQ-PRM-DOC | BR-PRM-DOC-016 | Positive/Create | P0 | Functional | ⬜ |
| TC-PRM-DOC-044 | REQ-PRM-DOC | BR-PRM-DOC-003 | Positive/M:M | P1 | Functional | ⬜ |
| TC-PRM-DOC-045 | REQ-PRM-DOC | — | Regression/Bug | P1 | Functional | ⬜ |
| TC-PRM-DOC-046 | REQ-PRM-DOC | BR-PRM-DOC-003 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-047 | REQ-PRM-DOC | BR-PRM-DOC-007 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-048 | REQ-PRM-DOC | BR-PRM-DOC-004 | Positive/Logic | P2 | Functional | ⬜ |
| TC-PRM-DOC-049 | REQ-PRM-DOC | — | Positive/Media | P2 | Functional | ⬜ |
| TC-PRM-DOC-050 | REQ-PRM-DOC | — | Positive/Logic | P1 | Functional | ⬜ |
| TC-PRM-DOC-051 | REQ-PRM-DOC | BR-PRM-DOC-008 | Positive/Schedule | P1 | Functional | ⬜ |
| TC-PRM-DOC-052 | REQ-PRM-DOC | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-DOC-053 | REQ-PRM-DOC | BR-PRM-DOC-016 | Positive/Update | P1 | Functional | ⬜ |
| TC-PRM-DOC-054 | REQ-PRM-DOC | — | Positive/M:M | P1 | Functional | ⬜ |
| TC-PRM-DOC-055 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-056 | REQ-PRM-DOC | — | Positive/Media | P2 | Functional | ⬜ |
| TC-PRM-DOC-057 | REQ-PRM-DOC | — | Positive/AJAX | P1 | Functional | ⬜ |
| TC-PRM-DOC-058 | REQ-PRM-DOC | — | Positive/AJAX | P1 | Functional | ⬜ |
| TC-PRM-DOC-059 | REQ-PRM-DOC | BR-PRM-DOC-012 | Positive/Delete | P1 | Functional | ⬜ |
| TC-PRM-DOC-060 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-061 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-062 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-063 | REQ-PRM-DOC | — | Negative/Exception | P2 | Functional | ⬜ |
| TC-PRM-DOC-064 | REQ-PRM-DOC | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-DOC-065 | REQ-PRM-DOC | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-DOC-066 | REQ-PRM-DOC | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-067 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-068 | REQ-PRM-DOC | BR-PRM-DOC-009 | Positive/Reader | P1 | Functional | ⬜ |
| TC-PRM-DOC-069 | REQ-PRM-DOC | BR-PRM-DOC-011 | Positive/Default | P2 | Functional | ⬜ |
| TC-PRM-DOC-070 | REQ-PRM-DOC | BR-PRM-DOC-005 | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-DOC-071 | REQ-PRM-DOC | BR-PRM-DOC-010 | Security/Filter | P1 | Security | ⬜ |
| TC-PRM-DOC-072 | REQ-PRM-DOC | BR-PRM-DOC-009 | Security/Filter | P0 | Security | ⬜ |
| TC-PRM-DOC-073 | REQ-PRM-DOC | BR-PRM-DOC-009 | Security/Filter | P1 | Security | ⬜ |
| TC-PRM-DOC-074 | REQ-PRM-DOC | BR-PRM-DOC-008 | Positive/Schedule | P1 | Functional | ⬜ |
| TC-PRM-DOC-075 | REQ-PRM-DOC | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-DOC-076 | REQ-PRM-DOC | BR-PRM-DOC-009 | Positive/AJAX | P1 | Functional | ⬜ |
| TC-PRM-DOC-077 | REQ-PRM-DOC | — | Positive/Empty | P2 | Functional | ⬜ |
| TC-PRM-DOC-078 | REQ-PRM-DOC | BR-PRM-DOC-009 | Security/Filter | P0 | Security | ⬜ |
| TC-PRM-DOC-079 | REQ-PRM-DOC | BR-PRM-DOC-009 | Security/Filter | P1 | Security | ⬜ |
| TC-PRM-DOC-080 | REQ-PRM-DOC | — | Negative/Exception | P2 | Functional | ⬜ |
| TC-PRM-DOC-081 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-082 | REQ-PRM-DOC | — | Positive | P2 | Functional | ⬜ |
| TC-PRM-DOC-083 | REQ-PRM-DOC | BR-PRM-DOC-017 | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-DOC-084 | REQ-PRM-DOC | BR-PRM-DOC-017 | Negative/Boundary | P1 | Functional | ⬜ |
| TC-PRM-DOC-085 | REQ-PRM-DOC | BR-PRM-DOC-017 | Security/Validation | P1 | Security | ⬜ |
| TC-PRM-DOC-086 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-087 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-088 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-089 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-090 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-091 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-092 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-DOC-093 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Regression | P0 | Security | ⬜ |
| TC-PRM-DOC-094 | REQ-PRM-DOC | BR-PRM-DOC-017 | Security/Regression | P0 | Security | ⬜ |
| TC-PRM-DOC-095 | REQ-PRM-DOC | BR-PRM-DOC-020 | Security/Regression | P0 | Security | ⬜ |
| TC-PRM-DOC-096 | REQ-PRM-DOC | BR-PRM-DOC-018 | Security/XSS | P0 | Security | ⬜ |
| TC-PRM-DOC-097 | REQ-PRM-DOC | BR-PRM-DOC-018 | Security/XSS | P0 | Security | ⬜ |
| TC-PRM-DOC-098 | REQ-PRM-DOC | — | Performance | P2 | Performance | ⬜ |
| TC-PRM-DOC-099 | REQ-PRM-DOC | — | Performance | P3 | Performance | ⬜ |
| TC-PRM-DOC-100 | REQ-PRM-DOC | BR-PRM-DOC-018 | Security/XSS | P1 | Security | ⬜ |
| TC-PRM-DOC-101 | REQ-PRM-DOC | BR-PRM-DOC-015 | Positive (after fix) | P2 | Functional | ⬜ |
| TC-PRM-DOC-102 | REQ-PRM-DOC | — | Negative/Validation | P2 | Functional | ⬜ |

---

## 20. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | Gate permission strings use singular form in controllers — Policy never invoked | TC-PRM-DOC-086 through TC-PRM-DOC-095 | CRITICAL | ⬜ |
| 2 | `CategoryController::index()` missing Gate check — any authenticated user can list | TC-PRM-DOC-093 | HIGH | ⬜ |
| 3 | Both `uploadImage()` methods missing Gate check — unauthorized upload | TC-PRM-DOC-094 | HIGH | ⬜ |
| 4 | Image upload limit 20 MB (`max:20048`) — too large and SVG not blocked | TC-PRM-DOC-084, TC-PRM-DOC-085 | HIGH | ⬜ |
| 5 | Article content stored as raw HTML — stored XSS via `{!! !!}` and AJAX `innerHTML` | TC-PRM-DOC-096, TC-PRM-DOC-097 | CRITICAL | ⬜ |
| 6 | `sort_order` not in `Category::$fillable` — mass assignment silently drops | TC-PRM-DOC-018 | MEDIUM | ⬜ |
| 7 | `sort_order` column missing from `doc_articles` migration — SQL error on `orderBy()` | TC-PRM-DOC-101 | HIGH | ⬜ |
| 8 | Form field name mismatch: `categories[]` vs expected `category_ids` | TC-PRM-DOC-045 | HIGH | ⬜ |
| 9 | No feature tests exist — only 17 structural unit tests | All TCs | HIGH | ⬜ |
| 10 | `DocumentationController` has dead stub methods (store/update/destroy) | — | LOW | ⬜ |
| 11 | `created_by` set in FormRequest `prepareForValidation()` instead of controller | — | MEDIUM | ⬜ |
| 12 | Inconsistent redirect route names (some with prefix, some without) | — | LOW | ⬜ |
| 13 | `getArticlesByCategory()` returns unlimited results — no pagination | — | LOW | ⬜ |
| 14 | Article content leaked to DOM via base64 `data-article-content` attributes | — | MEDIUM | ⬜ |
| 15 | `uploadImage()` returns plain string instead of proper JSON response | TC-PRM-DOC-081, TC-PRM-DOC-082 | LOW | ⬜ |

---

## 21. Route Reference

| Method | URI | Controller@Method | Name | Middleware |
|--------|-----|-------------------|------|-----------|
| GET | `/prime/documentation-mgt` | `DocumentationController@index` | `central.prime.documentation-mgt` | `web`, `auth` |
| GET | `/prime/documentation-intro` | `DocumentationController@mainDoc` | `central.prime.documentation-intro` | `web`, `auth` |
| GET | `/prime/documentation/articles/{categoryId}` | `DocumentationController@getArticlesByCategory` | `central.prime.documentation.articles.by-category` | `web`, `auth` |
| GET | `/prime/documentation-categories` | `DocumentationCategoryController@index` | `central.prime.documentation-categories.index` | `web`, `auth` |
| GET | `/prime/documentation-categories/create` | `DocumentationCategoryController@create` | `central.prime.documentation-categories.create` | `web`, `auth` |
| POST | `/prime/documentation-categories` | `DocumentationCategoryController@store` | `central.prime.documentation-categories.store` | `web`, `auth` |
| GET | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@show` | `central.prime.documentation-categories.show` | `web`, `auth` |
| GET | `/prime/documentation-categories/{id}/edit` | `DocumentationCategoryController@edit` | `central.prime.documentation-categories.edit` | `web`, `auth` |
| PUT | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@update` | `central.prime.documentation-categories.update` | `web`, `auth` |
| DELETE | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@destroy` | `central.prime.documentation-categories.destroy` | `web`, `auth` |
| GET | `/prime/documentation-categories/trash/view` | `DocumentationCategoryController@trashed` | `central.prime.documentation-categories.trashed` | `web`, `auth` |
| GET | `/prime/documentation-categories/{id}/restore` | `DocumentationCategoryController@restore` | `central.prime.documentation-categories.restore` | `web`, `auth` |
| DELETE | `/prime/documentation-categories/{id}/force-delete` | `DocumentationCategoryController@forceDelete` | `central.prime.documentation-categories.forceDelete` | `web`, `auth` |
| POST | `/prime/documentation-categories/{cat}/toggle-status` | `DocumentationCategoryController@toggleStatus` | `central.prime.documentation-categories.toggleStatus` | `web`, `auth` |
| POST | `/prime/documentation/upload-image` | `DocumentationCategoryController@uploadImage` | `central.prime.documentation.upload-image` | `web`, `auth` |
| GET | `/prime/documentation-articles` | `DocumentationArticleController@index` | `central.prime.documentation-articles.index` | `web`, `auth` |
| GET | `/prime/documentation-articles/create` | `DocumentationArticleController@create` | `central.prime.documentation-articles.create` | `web`, `auth` |
| POST | `/prime/documentation-articles` | `DocumentationArticleController@store` | `central.prime.documentation-articles.store` | `web`, `auth` |
| GET | `/prime/documentation-articles/{id}` | `DocumentationArticleController@show` | `central.prime.documentation-articles.show` | `web`, `auth` |
| GET | `/prime/documentation-articles/{id}/edit` | `DocumentationArticleController@edit` | `central.prime.documentation-articles.edit` | `web`, `auth` |
| PUT | `/prime/documentation-articles/{id}` | `DocumentationArticleController@update` | `central.prime.documentation-articles.update` | `web`, `auth` |
| DELETE | `/prime/documentation-articles/{id}` | `DocumentationArticleController@destroy` | `central.prime.documentation-articles.destroy` | `web`, `auth` |
| GET | `/prime/documentation-articles/trash/view` | `DocumentationArticleController@trashed` | `central.prime.documentation-articles.trashed` | `web`, `auth` |
| GET | `/prime/documentation-articles/{id}/restore` | `DocumentationArticleController@restore` | `central.prime.documentation-articles.restore` | `web`, `auth` |
| DELETE | `/prime/documentation-articles/{id}/force-delete` | `DocumentationArticleController@forceDelete` | `central.prime.documentation-articles.forceDelete` | `web`, `auth` |
| POST | `/prime/documentation-articles/{art}/toggle-status` | `DocumentationArticleController@toggleStatus` | `central.prime.documentation-articles.toggleStatus` | `web`, `auth` |
| POST | `/prime/documentation/articles/upload-image` | `DocumentationArticleController@uploadImage` | `central.prime.documentation-articles.upload-image` | `web`, `auth` |

---

## 22. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-DOC-001 | ⬜ | — | — | — | — |
| TC-PRM-DOC-002 | ⬜ | — | — | — | — |
| TC-PRM-DOC-003 | ⬜ | — | — | — | — |
| TC-PRM-DOC-004 | ⬜ | — | — | — | — |
| TC-PRM-DOC-005 | ⬜ | — | — | — | — |
| TC-PRM-DOC-006 | ⬜ | — | — | — | — |
| TC-PRM-DOC-007 | ⬜ | — | — | — | — |
| TC-PRM-DOC-008 | ⬜ | — | — | — | — |
| TC-PRM-DOC-009 | ⬜ | — | — | — | — |
| TC-PRM-DOC-010 | ⬜ | — | — | — | — |
| TC-PRM-DOC-011 | ⬜ | — | — | — | — |
| TC-PRM-DOC-012 | ⬜ | — | — | — | — |
| TC-PRM-DOC-013 | ⬜ | — | — | — | — |
| TC-PRM-DOC-014 | ⬜ | — | — | — | — |
| TC-PRM-DOC-015 | ⬜ | — | — | — | — |
| TC-PRM-DOC-016 | ⬜ | — | — | — | — |
| TC-PRM-DOC-017 | ⬜ | — | — | — | — |
| TC-PRM-DOC-018 | ⬜ | — | — | — | — |
| TC-PRM-DOC-019 | ⬜ | — | — | — | — |
| TC-PRM-DOC-020 | ⬜ | — | — | — | — |
| TC-PRM-DOC-021 | ⬜ | — | — | — | — |
| TC-PRM-DOC-022 | ⬜ | — | — | — | — |
| TC-PRM-DOC-023 | ⬜ | — | — | — | — |
| TC-PRM-DOC-024 | ⬜ | — | — | — | — |
| TC-PRM-DOC-025 | ⬜ | — | — | — | — |
| TC-PRM-DOC-026 | ⬜ | — | — | — | — |
| TC-PRM-DOC-027 | ⬜ | — | — | — | — |
| TC-PRM-DOC-028 | ⬜ | — | — | — | — |
| TC-PRM-DOC-029 | ⬜ | — | — | — | — |
| TC-PRM-DOC-030 | ⬜ | — | — | — | — |
| TC-PRM-DOC-031 | ⬜ | — | — | — | — |
| TC-PRM-DOC-032 | ⬜ | — | — | — | — |
| TC-PRM-DOC-033 | ⬜ | — | — | — | — |
| TC-PRM-DOC-034 | ⬜ | — | — | — | — |
| TC-PRM-DOC-035 | ⬜ | — | — | — | — |
| TC-PRM-DOC-036 | ⬜ | — | — | — | — |
| TC-PRM-DOC-037 | ⬜ | — | — | — | — |
| TC-PRM-DOC-038 | ⬜ | — | — | — | — |
| TC-PRM-DOC-039 | ⬜ | — | — | — | — |
| TC-PRM-DOC-040 | ⬜ | — | — | — | — |
| TC-PRM-DOC-041 | ⬜ | — | — | — | — |
| TC-PRM-DOC-042 | ⬜ | — | — | — | — |
| TC-PRM-DOC-043 | ⬜ | — | — | — | — |
| TC-PRM-DOC-044 | ⬜ | — | — | — | — |
| TC-PRM-DOC-045 | ⬜ | — | — | — | — |
| TC-PRM-DOC-046 | ⬜ | — | — | — | — |
| TC-PRM-DOC-047 | ⬜ | — | — | — | — |
| TC-PRM-DOC-048 | ⬜ | — | — | — | — |
| TC-PRM-DOC-049 | ⬜ | — | — | — | — |
| TC-PRM-DOC-050 | ⬜ | — | — | — | — |
| TC-PRM-DOC-051 | ⬜ | — | — | — | — |
| TC-PRM-DOC-052 | ⬜ | — | — | — | — |
| TC-PRM-DOC-053 | ⬜ | — | — | — | — |
| TC-PRM-DOC-054 | ⬜ | — | — | — | — |
| TC-PRM-DOC-055 | ⬜ | — | — | — | — |
| TC-PRM-DOC-056 | ⬜ | — | — | — | — |
| TC-PRM-DOC-057 | ⬜ | — | — | — | — |
| TC-PRM-DOC-058 | ⬜ | — | — | — | — |
| TC-PRM-DOC-059 | ⬜ | — | — | — | — |
| TC-PRM-DOC-060 | ⬜ | — | — | — | — |
| TC-PRM-DOC-061 | ⬜ | — | — | — | — |
| TC-PRM-DOC-062 | ⬜ | — | — | — | — |
| TC-PRM-DOC-063 | ⬜ | — | — | — | — |
| TC-PRM-DOC-064 | ⬜ | — | — | — | — |
| TC-PRM-DOC-065 | ⬜ | — | — | — | — |
| TC-PRM-DOC-066 | ⬜ | — | — | — | — |
| TC-PRM-DOC-067 | ⬜ | — | — | — | — |
| TC-PRM-DOC-068 | ⬜ | — | — | — | — |
| TC-PRM-DOC-069 | ⬜ | — | — | — | — |
| TC-PRM-DOC-070 | ⬜ | — | — | — | — |
| TC-PRM-DOC-071 | ⬜ | — | — | — | — |
| TC-PRM-DOC-072 | ⬜ | — | — | — | — |
| TC-PRM-DOC-073 | ⬜ | — | — | — | — |
| TC-PRM-DOC-074 | ⬜ | — | — | — | — |
| TC-PRM-DOC-075 | ⬜ | — | — | — | — |
| TC-PRM-DOC-076 | ⬜ | — | — | — | — |
| TC-PRM-DOC-077 | ⬜ | — | — | — | — |
| TC-PRM-DOC-078 | ⬜ | — | — | — | — |
| TC-PRM-DOC-079 | ⬜ | — | — | — | — |
| TC-PRM-DOC-080 | ⬜ | — | — | — | — |
| TC-PRM-DOC-081 | ⬜ | — | — | — | — |
| TC-PRM-DOC-082 | ⬜ | — | — | — | — |
| TC-PRM-DOC-083 | ⬜ | — | — | — | — |
| TC-PRM-DOC-084 | ⬜ | — | — | — | — |
| TC-PRM-DOC-085 | ⬜ | — | — | — | — |
| TC-PRM-DOC-086 | ⬜ | — | — | — | — |
| TC-PRM-DOC-087 | ⬜ | — | — | — | — |
| TC-PRM-DOC-088 | ⬜ | — | — | — | — |
| TC-PRM-DOC-089 | ⬜ | — | — | — | — |
| TC-PRM-DOC-090 | ⬜ | — | — | — | — |
| TC-PRM-DOC-091 | ⬜ | — | — | — | — |
| TC-PRM-DOC-092 | ⬜ | — | — | — | — |
| TC-PRM-DOC-093 | ⬜ | — | — | — | — |
| TC-PRM-DOC-094 | ⬜ | — | — | — | — |
| TC-PRM-DOC-095 | ⬜ | — | — | — | — |
| TC-PRM-DOC-096 | ⬜ | — | — | — | — |
| TC-PRM-DOC-097 | ⬜ | — | — | — | — |
| TC-PRM-DOC-098 | ⬜ | — | — | — | — |
| TC-PRM-DOC-099 | ⬜ | — | — | — | — |
| TC-PRM-DOC-100 | ⬜ | — | — | — | — |
| TC-PRM-DOC-101 | ⬜ | — | — | — | — |
| TC-PRM-DOC-102 | ⬜ | — | — | — | — |
