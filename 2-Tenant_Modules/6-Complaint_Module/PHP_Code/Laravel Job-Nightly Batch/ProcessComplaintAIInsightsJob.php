app/Jobs/ProcessComplaintAIInsightsJob.php

<?php

namespace App\Jobs;

use App\Services\ComplaintAIInsightEngine;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class ProcessComplaintAIInsightsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $complaintId;

    public int $tries = 3;
    public int $timeout = 120;

    public function __construct(int $complaintId)
    {
        $this->complaintId = $complaintId;
    }

    public function handle(ComplaintAIInsightEngine $engine): void
    {
        $engine->processComplaint($this->complaintId);
    }

    public function failed(Throwable $exception): void
    {
        \Log::error('AI Insight Job Failed', [
            'complaint_id' => $this->complaintId,
            'error' => $exception->getMessage()
        ]);
    }
}
