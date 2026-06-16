# ADDITIONAL INFORMATION FOR DEVELOPERS
---------------------------------------

A. Laravel Models Structure
```php
// app/Models/Library/FineSlabConfig.php
namespace App\Models\Library;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class FineSlabConfig extends Model
{
    use SoftDeletes;
    
    protected $table = 'lib_fine_slab_config';
    
    protected $fillable = [
        'name', 'membership_type_id', 'resource_type_id', 'fine_type',
        'max_fine_amount', 'max_fine_type', 'is_active', 'effective_from',
        'effective_to', 'priority'
    ];
    
    protected $casts = [
        'effective_from' => 'date',
        'effective_to' => 'date',
        'is_active' => 'boolean',
    ];
    
    public function membershipType()
    {
        return $this->belongsTo(MembershipType::class, 'membership_type_id');
    }
    
    public function resourceType()
    {
        return $this->belongsTo(ResourceType::class, 'resource_type_id');
    }
    
    public function slabDetails()
    {
        return $this->hasMany(FineSlabDetail::class, 'fine_slab_config_id');
    }
    
    public function fines()
    {
        return $this->hasMany(Fine::class, 'fine_slab_config_id');
    }
    
    // Scope for active slabs
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where('effective_from', '<=', now())
            ->where(function($q) {
                $q->whereNull('effective_to')
                  ->orWhere('effective_to', '>=', now());
            });
    }
    
    // Find applicable slab for member and resource
    public function scopeApplicableFor($query, $membershipTypeId, $resourceTypeId)
    {
        return $query->active()
            ->where(function($q) use ($membershipTypeId) {
                $q->whereNull('membership_type_id')
                  ->orWhere('membership_type_id', $membershipTypeId);
            })
            ->where(function($q) use ($resourceTypeId) {
                $q->whereNull('resource_type_id')
                  ->orWhere('resource_type_id', $resourceTypeId);
            })
            ->orderBy('priority', 'desc');
    }
}

// app/Models/Library/FineSlabDetail.php
namespace App\Models\Library;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class FineSlabDetail extends Model
{
    use SoftDeletes;
    
    protected $table = 'lib_fine_slab_details';
    
    protected $fillable = [
        'fine_slab_config_id', 'from_day', 'to_day', 'rate_per_day', 'rate_type'
    ];
    
    protected $casts = [
        'from_day' => 'integer',
        'to_day' => 'integer',
        'rate_per_day' => 'decimal:2',
    ];
    
    public function slabConfig()
    {
        return $this->belongsTo(FineSlabConfig::class, 'fine_slab_config_id');
    }
}

// app/Models/Library/Fine.php (Enhanced)
namespace App\Models\Library;

use Illuminate\Database\Eloquent\Model;

class Fine extends Model
{
    protected $table = 'lib_fines';
    
    protected $fillable = [
        'transaction_id', 'member_id', 'fine_type', 'amount', 'days_overdue',
        'calculated_from', 'calculated_to', 'fine_slab_config_id',
        'calculation_breakdown', 'waived_amount', 'waived_by_id',
        'waived_reason', 'waived_at', 'status', 'notes'
    ];
    
    protected $casts = [
        'calculated_from' => 'date',
        'calculated_to' => 'date',
        'waived_at' => 'datetime',
        'calculation_breakdown' => 'array',
        'amount' => 'decimal:2',
        'waived_amount' => 'decimal:2',
    ];
    
    public function transaction()
    {
        return $this->belongsTo(Transaction::class, 'transaction_id');
    }
    
    public function member()
    {
        return $this->belongsTo(Member::class, 'member_id');
    }
    
    public function slabConfig()
    {
        return $this->belongsTo(FineSlabConfig::class, 'fine_slab_config_id');
    }
    
    public function waivedBy()
    {
        return $this->belongsTo(User::class, 'waived_by_id');
    }
    
    public function payments()
    {
        return $this->hasMany(FinePayment::class, 'fine_id');
    }
    
    // Accessor for net amount (amount - waived)
    public function getNetAmountAttribute()
    {
        return $this->amount - ($this->waived_amount ?? 0);
    }
    
    // Check if fully paid
    public function getIsFullyPaidAttribute()
    {
        $totalPaid = $this->payments()->sum('amount_paid');
        return $totalPaid >= $this->net_amount;
    }
}
```

B. Laravel Service Class for Fine Calculation
```php
// app/Services/Library/FineCalculationService.php
namespace App\Services\Library;

use App\Models\Library\FineSlabConfig;
use App\Models\Library\FineSlabDetail;
use App\Models\Library\Fine;
use App\Models\Library\Transaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class FineCalculationService
{
    /**
     * Calculate fine for an overdue transaction
     */
    public function calculateFine(Transaction $transaction): array
    {
        $daysOverdue = now()->startOfDay()->diffInDays($transaction->due_date);
        
        if ($daysOverdue <= 0) {
            return [
                'amount' => 0,
                'breakdown' => null,
                'slab_config_id' => null
            ];
        }
        
        // Get member and resource details
        $member = $transaction->member;
        $copy = $transaction->copy;
        $book = $copy->book;
        
        // Find applicable slab config
        $slabConfig = FineSlabConfig::applicableFor(
            $member->membership_type_id,
            $book->resource_type_id
        )->first();
        
        if (!$slabConfig) {
            // Fallback to default calculation (if any)
            return $this->calculateDefaultFine($daysOverdue);
        }
        
        // Calculate fine using slab
        return $this->calculateSlabFine($slabConfig, $daysOverdue, $copy->purchase_price);
    }
    
    /**
     * Calculate fine based on slab configuration
     */
    protected function calculateSlabFine(FineSlabConfig $slabConfig, int $daysOverdue, float $bookCost): array
    {
        $breakdown = [
            'total_days' => $daysOverdue,
            'breakdown' => [],
            'total_fine' => 0
        ];
        
        $remainingDays = $daysOverdue;
        $totalFine = 0;
        
        // Get all slab details ordered by from_day
        $slabDetails = $slabConfig->slabDetails()->orderBy('from_day')->get();
        
        foreach ($slabDetails as $slab) {
            if ($remainingDays <= 0) {
                break;
            }
            
            $slabDays = $slab->to_day - $slab->from_day + 1;
            $applicableDays = min($remainingDays, $slabDays);
            
            // Calculate fine for this slab
            if ($slab->rate_type === 'Fixed') {
                $slabFine = $applicableDays * $slab->rate_per_day;
            } else { // Percentage
                $slabFine = $applicableDays * ($bookCost * $slab->rate_per_day / 100);
            }
            
            $totalFine += $slabFine;
            
            $breakdown['breakdown'][] = [
                'from_day' => $slab->from_day,
                'to_day' => $slab->to_day,
                'days_applied' => $applicableDays,
                'rate' => $slab->rate_per_day,
                'rate_type' => $slab->rate_type,
                'slab_fine' => $slabFine
            ];
            
            $remainingDays -= $applicableDays;
        }
        
        // Apply max cap
        if ($slabConfig->max_fine_type === 'Fixed' && $slabConfig->max_fine_amount) {
            $totalFine = min($totalFine, $slabConfig->max_fine_amount);
        } elseif ($slabConfig->max_fine_type === 'BookCost' && $bookCost > 0) {
            $totalFine = min($totalFine, $bookCost);
        }
        
        $breakdown['total_fine'] = $totalFine;
        
        return [
            'amount' => $totalFine,
            'breakdown' => $breakdown,
            'slab_config_id' => $slabConfig->id
        ];
    }
    
    /**
     * Create fine record for transaction
     */
    public function createFine(Transaction $transaction): ?Fine
    {
        $calculation = $this->calculateFine($transaction);
        
        if ($calculation['amount'] <= 0) {
            return null;
        }
        
        return DB::transaction(function () use ($transaction, $calculation) {
            $fine = Fine::create([
                'transaction_id' => $transaction->id,
                'member_id' => $transaction->member_id,
                'fine_type' => 'Late Return',
                'amount' => $calculation['amount'],
                'days_overdue' => $calculation['breakdown']['total_days'] ?? 0,
                'calculated_from' => $transaction->due_date,
                'calculated_to' => now(),
                'fine_slab_config_id' => $calculation['slab_config_id'],
                'calculation_breakdown' => $calculation['breakdown'],
                'status' => 'Pending'
            ]);
            
            // Update member outstanding fines
            $transaction->member->increment('outstanding_fines', $calculation['amount']);
            
            return $fine;
        });
    }
    
    /**
     * Recalculate fine for existing fine record
     */
    public function recalculateFine(Fine $fine): Fine
    {
        $transaction = $fine->transaction;
        $calculation = $this->calculateFine($transaction);
        
        $oldAmount = $fine->amount;
        $newAmount = $calculation['amount'];
        
        if ($oldAmount != $newAmount) {
            DB::transaction(function () use ($fine, $calculation, $oldAmount, $newAmount) {
                $fine->update([
                    'amount' => $newAmount,
                    'days_overdue' => $calculation['breakdown']['total_days'] ?? 0,
                    'calculated_to' => now(),
                    'fine_slab_config_id' => $calculation['slab_config_id'],
                    'calculation_breakdown' => $calculation['breakdown']
                ]);
                
                // Update member outstanding fines (adjust difference)
                $member = $fine->member;
                $member->outstanding_fines = $member->outstanding_fines - $oldAmount + $newAmount;
                $member->save();
            });
        }
        
        return $fine->fresh();
    }
}
```

C. Scheduled Jobs (Laravel Console Kernel)
```php
// app/Console/Kernel.php

protected function schedule(Schedule $schedule)
{
    // Run fine calculation daily at 2 AM
    $schedule->command('library:calculate-fines')->dailyAt('02:00');
    
    // Send overdue reminders daily at 9 AM
    $schedule->command('library:send-overdue-reminders')->dailyAt('09:00');
    
    // Send due date reminders daily at 10 AM
    $schedule->command('library:send-due-reminders')->dailyAt('10:00');
    
    // Update member engagement scores weekly on Sunday at 3 AM
    $schedule->command('library:update-engagement-scores')->weeklyOn(0, '03:00');
    
    // Generate popularity trends daily at 1 AM
    $schedule->command('library:update-popularity-trends')->dailyAt('01:00');
}

// app/Console/Commands/CalculateFines.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Library\Transaction;
use App\Services\Library\FineCalculationService;

class CalculateFines extends Command
{
    protected $signature = 'library:calculate-fines';
    protected $description = 'Calculate fines for overdue transactions';
    
    public function handle(FineCalculationService $fineService)
    {
        $this->info('Starting fine calculation...');
        
        $overdueTransactions = Transaction::where('status', 'issued')
            ->where('due_date', '<', now())
            ->whereDoesntHave('fines', function($query) {
                $query->where('fine_type', 'Late Return')
                      ->where('status', 'Pending');
            })
            ->get();
        
        $bar = $this->output->createProgressBar($overdueTransactions->count());
        $bar->start();
        
        $count = 0;
        foreach ($overdueTransactions as $transaction) {
            try {
                $fine = $fineService->createFine($transaction);
                if ($fine) {
                    $count++;
                }
            } catch (\Exception $e) {
                Log::error('Fine calculation failed for transaction: ' . $transaction->id, [
                    'error' => $e->getMessage()
                ]);
            }
            $bar->advance();
        }
        
        $bar->finish();
        $this->newLine();
        $this->info("Completed! Created {$count} new fines.");
    }
}
```

D. API Endpoints (routes/api.php)
```php
// Library Module API Routes
Route::prefix('library')->middleware(['auth:sanctum'])->group(function () {
    
    // Fine Slab Configuration
    Route::apiResource('fine-slabs', 'Library\FineSlabConfigController');
    Route::post('fine-slabs/{fine_slab}/slab-details', 'Library\FineSlabConfigController@addSlabDetail');
    Route::delete('fine-slabs/{fine_slab}/slab-details/{detail}', 'Library\FineSlabConfigController@removeSlabDetail');
    
    // Fine Management
    Route::get('fines/overdue', 'Library\FineController@overdueList');
    Route::post('fines/{fine}/pay', 'Library\FineController@pay');
    Route::post('fines/{fine}/waive', 'Library\FineController@waive');
    Route::post('fines/{fine}/recalculate', 'Library\FineController@recalculate');
    Route::get('fines/reports/summary', 'Library\FineController@reportSummary');
    
    // Transactions
    Route::post('transactions/issue', 'Library\TransactionController@issue');
    Route::post('transactions/return', 'Library\TransactionController@return');
    Route::post('transactions/{transaction}/renew', 'Library\TransactionController@renew');
    Route::get('transactions/current/{member}', 'Library\TransactionController@currentIssues');
    
    // Members
    Route::get('members/{member}/360', 'Library\MemberController@get360View');
    Route::get('members/{member}/fines', 'Library\MemberController@getFines');
    Route::get('members/{member}/history', 'Library\MemberController@getHistory');
    
    // Books
    Route::get('books/search', 'Library\BookController@search');
    Route::get('books/{book}/availability', 'Library\BookController@checkAvailability');
    Route::post('books/{book}/reserve', 'Library\ReservationController@reserve');
    
    // Dashboard
    Route::get('dashboard/stats', 'Library\DashboardController@getStats');
    Route::get('dashboard/trends', 'Library\DashboardController@getTrends');
});
```

