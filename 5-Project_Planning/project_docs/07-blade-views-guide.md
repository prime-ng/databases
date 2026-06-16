# Blade Views Guide

## Blade File Location — Universal Rule

```
Modules/<ModuleName>/resources/views/<feature-folder>/<file>.blade.php
```

## Blade View Namespace (used in controllers)

```php
// Format: '<modulename-lowercase>::<folder>.<filename>'
'hpc::learning-outcomes.index'
'schoolsetup::school-class.index'
'smarttimetable::activity.index'
'prime::tenant.index'
'billing::billing-management.index'
```

## Shared Global Components

```
resources/views/components/
├── backend/                    <- Backend panel components (tenant)
│   ├── card/
│   │   └── header.blade.php
│   ├── components/
│   │   ├── breadcrum.blade.php
│   │   ├── create-dropdown.blade.php
│   │   ├── filter.blade.php
│   │   ├── menu-item.blade.php
│   │   ├── pre-loader.blade.php
│   │   ├── search.blade.php
│   │   └── search-filter-option.blade.php
│   ├── email/template.blade.php
│   ├── form/                   <- Reusable form elements
│   ├── layouts/                <- Main backend layout (AdminLTE v4)
│   ├── partials/               <- Header, sidebar, footer
│   ├── tab/
│   └── table/
├── frontend/                   <- Student portal
│   ├── form/
│   └── layout/
└── prime/                      <- Prime admin specific
    ├── card/
    ├── components/
    ├── form/
    ├── layouts/                <- Prime admin layout
    ├── partials/
    └── table/
```

## How to Use Shared Components

```blade
{{-- Backend layout (for tenant modules) --}}
<x-backend.layouts.app>
    {{-- content goes here --}}
</x-backend.layouts.app>

{{-- Prime layout (for prime modules) --}}
<x-prime.layouts.app>
    {{-- content goes here --}}
</x-prime.layouts.app>

{{-- Breadcrumb --}}
<x-backend.components.breadcrum title="Learning Outcomes" :links="[
    ['title' => 'HPC', 'url' => route('hpc.hpc.index')],
    ['title' => 'Learning Outcomes', 'url' => '']
]" />

{{-- Card header with Add button --}}
<x-backend.card.header title="Learning Outcomes" url="hpc.learning-outcomes" />
```

## Standard Index View Pattern

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="Learning Outcomes" :links="[
        ['title' => 'HPC', 'url' => route('hpc.hpc.index')],
        ['title' => 'Learning Outcomes', 'url' => '']
    ]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <x-backend.card.header title="Learning Outcomes" url="hpc.learning-outcomes" />
                    <div class="card-body">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Parameter</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($outcomes as $outcome)
                                    <tr class="align-middle">
                                        <td>{{ $outcome->name }}</td>
                                        <td>{{ $outcome->parameter->name ?? '-' }}</td>
                                        <td>
                                            @if($outcome->is_active)
                                                <span class="badge bg-success">Active</span>
                                            @else
                                                <span class="badge bg-danger">Inactive</span>
                                            @endif
                                        </td>
                                        <td>
                                            <a href="{{ route('hpc.learning-outcomes.edit', $outcome) }}"
                                               class="btn btn-sm btn-primary"><i class="bi bi-pencil"></i></a>
                                            <form action="{{ route('hpc.learning-outcomes.destroy', $outcome) }}"
                                                  method="POST" class="d-inline">
                                                @csrf @method('DELETE')
                                                <button class="btn btn-sm btn-danger"><i class="bi bi-trash"></i></button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr><td colspan="4" class="text-center">No records found.</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                        {{ $outcomes->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

## Standard Create/Edit Form Pattern

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="Add Learning Outcome" :links="[
        ['title' => 'Learning Outcomes', 'url' => route('hpc.learning-outcomes.index')],
        ['title' => 'Add New', 'url' => '']
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

                        <form action="{{ route('hpc.learning-outcomes.store') }}" method="POST">
                            @csrf
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="name" class="form-label">Name <span class="text-danger">*</span></label>
                                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                                           name="name" value="{{ old('name') }}" required>
                                    @error('name') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="hpc_parameter_id" class="form-label">Parameter</label>
                                    <select class="form-select" name="hpc_parameter_id">
                                        <option value="">-- Select --</option>
                                        @foreach($parameters as $param)
                                            <option value="{{ $param->id }}"
                                                {{ old('hpc_parameter_id') == $param->id ? 'selected' : '' }}>
                                                {{ $param->name }}
                                            </option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <button type="submit" class="btn btn-primary">Save</button>
                            <a href="{{ route('hpc.learning-outcomes.index') }}" class="btn btn-secondary">Cancel</a>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

## PDF Blade Files — Special Rules (HPC Module - Decision D13)

```
RULES FOR ALL PDF TEMPLATES (*_pdf.blade.php):
 NO Bootstrap classes -- use inline styles only
 NO flexbox or CSS grid -- use <table> for ALL layouts
 NO JavaScript
 NO Blade components (<x-...>)
 YES: One self-contained file per template
 YES: $css array at top for all styles
 YES: Helper closures for repeated logic
 YES: Full <!DOCTYPE html> document
 YES: <table width="100%"> on EVERY nested table (DomPDF requirement)
```

## Emoji Assets in HPC

```blade
<img src="{{ asset('emoji/happy.png') }}" width="24" />
<img src="{{ asset('emoji/no.png') }}" width="24" />
```
