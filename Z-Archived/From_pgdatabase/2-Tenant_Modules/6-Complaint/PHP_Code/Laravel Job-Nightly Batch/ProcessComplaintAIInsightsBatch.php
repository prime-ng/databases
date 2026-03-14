app/Console/Commands/ProcessComplaintAIInsightsBatch.php

<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Jobs\ProcessComplaintAIInsightsJob;

class ProcessComplaintAIInsightsBatch extends Command
{
    protected $signature = 'complaints:process-ai-insights 
                            {--days=7 : Process complaints created in last N days}';

    protected $description = 'Nightly batch to calculate AI insights for complaints';

    public function handle(): int
    {
        $days = (int) $this->option('days');

        $this->info("Processing complaints from last {$days} days...");

        DB::table('cmp_complaints')
            ->where('created_at', '>=', now()->subDays($days))
            ->orderBy('id')
            ->chunkById(200, function ($complaints) {
                foreach ($complaints as $complaint) {
                    ProcessComplaintAIInsightsJob::dispatch($complaint->id)
                        ->onQueue('complaint-ai');
                }
            });

        $this->info('Complaint AI Insight jobs dispatched successfully.');

        return self::SUCCESS;
    }
}
