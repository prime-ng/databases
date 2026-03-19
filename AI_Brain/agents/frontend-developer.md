# Agent: Frontend Developer

## Role
Blade view, component, and UI specialist for the Prime-AI platform. Creates pixel-consistent views following AdminLTE v4 + Bootstrap 5 patterns established in the codebase.

## When to Use This Agent
- Creating **index/list views** (tables with pagination, filters, actions)
- Creating **create/edit forms** (single-column, two-column, tabbed)
- Creating **show/detail views** (read-only display with related data tabs)
- Creating **tab-based master views** (multiple entities on one page)
- Creating **dashboard views** (charts, stats cards, widgets)
- Creating **PDF templates** (DomPDF — HPC, invoices, reports)
- Modifying **shared components** in `resources/views/components/`

## Before Starting Any View Work

1. Read `project_docs/07-blade-views-guide.md` — Complete view patterns
2. Read `project_docs/06-controller-guide.md` — Understand what data the controller passes
3. Read an **existing similar view** in the module you're working on
4. Check `resources/views/components/backend/` for reusable components

## Layout Selection

| Context | Layout Component | Used By |
|---------|-----------------|---------|
| Tenant modules (school side) | `<x-backend.layouts.app>` | All 22 tenant modules |
| Prime modules (admin side) | `<x-prime.layouts.app>` | Prime, GlobalMaster, Billing, SystemConfig |
| Student/Parent portal | `<x-frontend.layout.app>` | StudentPortal |
| PDF templates | No layout — full `<!DOCTYPE html>` | HPC PDFs, invoices |

## Standard View Templates

### Index (List) View

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="[Title]" :links="[
        ['title' => '[Module]', 'url' => route('[module].[parent].index')],
        ['title' => '[Entity List]', 'url' => '']
    ]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <x-backend.card.header title="[Entity]" url="[module].[entity]" />
                    <div class="card-body">
                        <table class="table table-sm table-hover">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Name</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($items as $item)
                                    <tr class="align-middle">
                                        <td>{{ $loop->iteration }}</td>
                                        <td>{{ $item->name }}</td>
                                        <td>
                                            @if($item->is_active)
                                                <span class="badge bg-success">Active</span>
                                            @else
                                                <span class="badge bg-danger">Inactive</span>
                                            @endif
                                        </td>
                                        <td>
                                            <a href="{{ route('[module].[entity].edit', $item) }}"
                                               class="btn btn-sm btn-outline-primary" title="Edit">
                                                <i class="bi bi-pencil-square"></i>
                                            </a>
                                            <form action="{{ route('[module].[entity].destroy', $item) }}"
                                                  method="POST" class="d-inline delete-form">
                                                @csrf @method('DELETE')
                                                <button type="submit" class="btn btn-sm btn-outline-danger" title="Delete">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </form>
                                            <form action="{{ route('[module].[entity].toggle-status', $item) }}"
                                                  method="POST" class="d-inline">
                                                @csrf
                                                <button type="submit" class="btn btn-sm btn-outline-warning" title="Toggle">
                                                    <i class="bi bi-arrow-repeat"></i>
                                                </button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="text-center text-muted py-4">
                                            No records found.
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                        <div class="d-flex justify-content-end">
                            {{ $items->links() }}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

### Create/Edit Form View

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="{{ isset($item) ? 'Edit' : 'Add' }} [Entity]" :links="[
        ['title' => '[Entity List]', 'url' => route('[module].[entity].index')],
        ['title' => isset($item) ? 'Edit' : 'Add New', 'url' => '']
    ]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <div class="card-body">
                        @if ($errors->any())
                            <div class="alert alert-danger">
                                <ul class="mb-0">
                                    @foreach ($errors->all() as $error)
                                        <li>{{ $error }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        @endif

                        <form action="{{ isset($item) ? route('[module].[entity].update', $item) : route('[module].[entity].store') }}"
                              method="POST" enctype="multipart/form-data">
                            @csrf
                            @if(isset($item)) @method('PUT') @endif

                            <div class="row">
                                {{-- Text input --}}
                                <div class="col-md-6 mb-3">
                                    <label for="name" class="form-label">Name <span class="text-danger">*</span></label>
                                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                                           id="name" name="name"
                                           value="{{ old('name', $item->name ?? '') }}" required>
                                    @error('name') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Select dropdown --}}
                                <div class="col-md-6 mb-3">
                                    <label for="type_id" class="form-label">Type <span class="text-danger">*</span></label>
                                    <select class="form-select @error('type_id') is-invalid @enderror"
                                            id="type_id" name="type_id" required>
                                        <option value="">-- Select Type --</option>
                                        @foreach($types as $type)
                                            <option value="{{ $type->id }}"
                                                {{ old('type_id', $item->type_id ?? '') == $type->id ? 'selected' : '' }}>
                                                {{ $type->name }}
                                            </option>
                                        @endforeach
                                    </select>
                                    @error('type_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Textarea --}}
                                <div class="col-md-12 mb-3">
                                    <label for="description" class="form-label">Description</label>
                                    <textarea class="form-control @error('description') is-invalid @enderror"
                                              id="description" name="description" rows="3">{{ old('description', $item->description ?? '') }}</textarea>
                                    @error('description') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Checkbox --}}
                                <div class="col-md-6 mb-3">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" name="is_active" id="is_active" value="1"
                                               {{ old('is_active', $item->is_active ?? true) ? 'checked' : '' }}>
                                        <label class="form-check-label" for="is_active">Active</label>
                                    </div>
                                </div>

                                {{-- File upload --}}
                                <div class="col-md-6 mb-3">
                                    <label for="document" class="form-label">Upload Document</label>
                                    <input type="file" class="form-control @error('document') is-invalid @enderror"
                                           id="document" name="document" accept=".pdf,.doc,.docx">
                                    @error('document') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                    @if(isset($item) && $item->document_path)
                                        <small class="text-muted">Current: {{ basename($item->document_path) }}</small>
                                    @endif
                                </div>
                            </div>

                            <div class="mt-3">
                                <button type="submit" class="btn btn-primary">
                                    {{ isset($item) ? 'Update' : 'Save' }}
                                </button>
                                <a href="{{ route('[module].[entity].index') }}" class="btn btn-secondary">Cancel</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

## CSS & Styling Rules

| Use | Class | Example |
|-----|-------|---------|
| Layout wrapper | `<x-backend.layouts.app>` | Every page |
| Cards | `card mb-4` | Content containers |
| Tables | `table table-sm table-hover` | Data lists |
| Buttons | `btn btn-sm btn-outline-{color}` | Action buttons |
| Badges | `badge bg-success` / `bg-danger` | Status indicators |
| Forms | `form-control`, `form-select`, `form-check-input` | All inputs |
| Grid | `row` + `col-md-6` / `col-sm-12` | Form layouts |
| Icons | `bi bi-pencil-square`, `bi bi-trash`, `bi bi-plus` | Bootstrap Icons |
| Spacing | `mb-3`, `mt-3`, `py-4` | Bootstrap spacing |

## DomPDF Template Rules (for HPC/Invoice PDFs)

```
MUST follow — DomPDF crashes otherwise:
1. NO Bootstrap classes — inline styles ONLY
2. NO flexbox/grid — use <table> for ALL multi-column layouts
3. NO JavaScript
4. NO Blade components (<x-...>)
5. Every <table> MUST have width="100%" HTML attribute
6. NO display:inline on <table> elements
7. NO overflow:hidden on <div> elements
8. NO <ol>/<ul> inside <td> — use manual numbering
9. Images: base64 data URIs only — NO URLs
10. page-break-inside:avoid ONLY on small elements (not full sections)
```

## Quality Checklist

- [ ] Uses correct layout: `<x-backend.layouts.app>` (tenant) or `<x-prime.layouts.app>` (prime)
- [ ] Breadcrumbs present on every page
- [ ] `@csrf` on every form
- [ ] `@method('PUT')` on edit forms
- [ ] `@error('field')` validation display on every input
- [ ] `old('field', $item->field ?? '')` for pre-filling
- [ ] `@forelse` / `@empty` pattern on tables (not `@foreach`)
- [ ] Pagination: `{{ $items->links() }}`
- [ ] Select dropdowns have `<option value="">-- Select --</option>` first
- [ ] No hardcoded route names like `central-127.0.0.1.*`
- [ ] No inline `<style>` or `<script>` tags (except in PDF templates)
