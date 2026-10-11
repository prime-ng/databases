# EventEngine Module: Architecture & Implementation Guide

This document serves as the complete technical specification for developing the **EventEngine** module in our Laravel application. The goal of this module is to abstract and standardize database lifecycle hooks (Observers), decouple heavy execution tasks via background queues, and provide real-time monitoring via Laravel Horizon.

---

## 1. Overview of Laravel Observers

Laravel Observers allow us to group model lifecycle event handlers into a single class. They act as the primary triggers within our **EventEngine**.

### Available Lifecycle Events

| Event Method | When It Triggers | Recommended Use Cases in EventEngine |
| :--- | :--- | :--- |
| `retrieved` | After an existing model is fetched from DB. | Logging reads, decrypting sensitive fields. |
| `creating` | **Before** insertion into the DB. | Generating slugs, UUIDs, initial default statuses. |
| `created` | **After** insertion into the DB. | Dispatching welcome emails, audit logs, ledger entries. |
| `updating` | **Before** an existing model is updated. | Validating state machines, setting `updated_by` IDs. |
| `updated` | **After** an existing model is updated. | Clearing query caches, notifying connected services. |
| `saving` | **Before** *either* creation or update. | Sanitizing input data, running shared validations. |
| `saved` | **After** *either* creation or update. | Syncing search indexes (Elasticsearch/Meilisearch). |
| `deleting` | **Before** deletion (or soft-deletion). | Cleaning up dependent files/images, cascade checks. |
| `deleted` | **After** deletion. | Final cleanup records, metrics logging. |
| `restoring` | **Before** a soft-deleted model is restored. | Checking if parent relations still exist. |
| `restored` | **After** a soft-deleted model is restored. | Reactivating dependent records. |

---

## 2. Standard Implementation Workflow

### Step 1: Generate an Observer
For any Eloquent model (e.g., `User`), create an observer using Artisan:
```bash
php artisan make:observer UserObserver --model=User
```

### Step 2: Implement Event Hooks
Structure your observer to remain lightweight. Avoid executing heavy computations or external API calls synchronously inside these methods.

```php
namespace App\Observers;

use App\Models\User;
use App\Jobs\ProcessUserWelcomeTask;
use Illuminate\Support\Str;

class UserObserver
{
    public function creating(User $user): void
    {
        $user->username = Str::slug($user->name);
    }

    public function created(User $user): void
    {
        // Always dispatch jobs after database transactions commit to prevent race conditions
        ProcessUserWelcomeTask::dispatch($user)->afterCommit();
    }
}
```

### Step 3: Register in Service Provider
Register the observer inside `app/Providers/AppServiceProvider.php` (or a dedicated `EventEngineServiceProvider`):

```php
namespace App\Providers;

use App\Models\User;
use App\Observers\UserObserver;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        User::observe(UserObserver::class);
    }
}
```

---

## 3. Asynchronous Processing & Queue Best Practices

To prevent blocking HTTP request cycles, heavy tasks triggered by the EventEngine must be dispatched to a background queue using Laravel Jobs.

### Creating the Background Job
```bash
php artisan make:job ProcessUserWelcomeTask
```

Implementation guidelines:
* Implement the `ShouldQueue` contract.
* Use `SerializesModels` to cleanly pass Eloquent models to the queue worker.
* Always chain `->afterCommit()` when dispatching from model events to prevent `ModelNotFoundException` issues if the background worker picks up the job before the database transaction commits.

```php
namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;
use App\Mail\WelcomeEmail;

class ProcessUserWelcomeTask implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60; // Wait 60 seconds before retrying failed attempts

    public function __construct(public User $user) {}

    public function handle(): void
    {
        Mail::to($this->user->email)->send(new WelcomeEmail($this->user));
    }
}
```

---

## 4. Real-Time Monitoring with Laravel Horizon

For production environments, **Laravel Horizon** provides robust oversight over our Redis-powered queue throughput and failure rates.

### Configuration (`config/horizon.php`)
Set up environment-specific supervisors to scale workers based on workload:

```php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default', 'emails', 'events'],
            'balance' => 'auto',
            'autoScalingStrategy' => 'time',
            'minProcesses' => 2,
            'maxProcesses' => 15,
            'tries' => 3,
        ],
    ],
    'local' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default', 'emails'],
            'balance' => 'simple',
            'processes' => 3,
        ],
    ],
],
```

### Securing the Dashboard (`app/Providers/HorizonServiceProvider.php`)
Protect the `/horizon` endpoint in production environments:
```php
protected function gate(): void
{
    Gate::define('viewHorizon', function ($user) {
        return in_array($user->email, [
            'lead-developer@example.com',
            'cto@example.com',
        ]);
    });
}
```

---

## 5. Developer Checklist for EventEngine Module

1. **Keep Observers Thin:** Only handle direct state mutations (e.g., setting slugs, hashing tokens) synchronously. Offload emails, PDF generation, and webhooks to queued jobs.
2. **Transaction Safety:** Always use `->afterCommit()` when dispatching jobs from `created`, `updated`, or `deleted` observer hooks.
3. **Queue Segmentation:** Route heavy reporting tasks to dedicated queues (e.g., `reports`) and user-facing notifications to fast queues (e.g., `emails`).
4. **Error Handling:** Define retry limits (`$tries`) and backoff intervals on your background jobs to gracefully handle transient network or third-party API failures.