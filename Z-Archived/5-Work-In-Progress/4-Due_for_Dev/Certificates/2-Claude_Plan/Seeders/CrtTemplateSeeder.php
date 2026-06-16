<?php

namespace Modules\Certificate\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CrtTemplateSeeder extends Seeder
{
    /**
     * Seed one default starter template per certificate type.
     * Each template includes:
     *   - Minimal HTML with 5 mandatory merge fields
     *   - variables_json declaring those 5 field names
     *   - is_default = true, page_size = 'a4', orientation = 'portrait'
     *   - A corresponding crt_template_versions row (version_no = 1)
     *
     * Safe to re-run: skips if a default template already exists for the type.
     * Depends on: CrtCertificateTypeSeeder (certificate_type_id lookup by code).
     */
    public function run(): void
    {
        $now = now();

        $templates = [
            'BON' => [
                'name' => 'Bonafide Certificate — Standard A4',
                'content' => $this->bonafideHtml(),
            ],
            'TC' => [
                'name' => 'Transfer Certificate — Standard A4',
                'content' => $this->tcHtml(),
            ],
            'CHR' => [
                'name' => 'Character Certificate — Standard A4',
                'content' => $this->characterHtml(),
            ],
            'MRT' => [
                'name' => 'Merit Certificate — Landscape A4',
                'content' => $this->meritHtml(),
            ],
            'SPT' => [
                'name' => 'Sports Certificate — Landscape A4',
                'content' => $this->sportsHtml(),
            ],
        ];

        // Standard merge fields used across all basic templates
        $standardVariables = [
            'school_name',
            'student_name',
            'certificate_no',
            'issue_date',
            'principal_name',
        ];

        foreach ($templates as $typeCode => $data) {
            // Look up certificate type
            $type = DB::table('crt_certificate_types')->where('code', $typeCode)->first();

            if (! $type) {
                $this->command?->warn("CrtTemplateSeeder: certificate type [{$typeCode}] not found — skipping.");
                continue;
            }

            // Skip if default template already exists for this type
            $exists = DB::table('crt_templates')
                ->where('certificate_type_id', $type->id)
                ->where('is_default', 1)
                ->whereNull('deleted_at')
                ->exists();

            if ($exists) {
                $this->command?->info("CrtTemplateSeeder: default template for [{$typeCode}] already exists — skipping.");
                continue;
            }

            // Insert template
            $templateId = DB::table('crt_templates')->insertGetId([
                'certificate_type_id'      => $type->id,
                'name'                     => $data['name'],
                'template_content'         => $data['content'],
                'variables_json'           => json_encode($standardVariables),
                'page_size'                => 'a4',
                'orientation'              => 'portrait',
                'is_default'               => 1,
                'signature_placement_json' => null,
                'version_no'               => 1,
                'is_active'                => 1,
                'created_by'               => 1,
                'updated_by'               => 1,
                'created_at'               => $now,
                'updated_at'               => $now,
            ]);

            // Insert corresponding version_no = 1 snapshot
            DB::table('crt_template_versions')->insert([
                'template_id'      => $templateId,
                'version_no'       => 1,
                'template_content' => $data['content'],
                'variables_json'   => json_encode($standardVariables),
                'saved_by'         => 1,
                'saved_at'         => $now,
                'is_active'        => 1,
                'created_by'       => 1,
                'updated_by'       => 1,
                'created_at'       => $now,
                'updated_at'       => $now,
            ]);

            $this->command?->info("CrtTemplateSeeder: template seeded for [{$typeCode}] (template_id={$templateId}).");
        }
    }

    // -------------------------------------------------------------------------
    // HTML template bodies — minimal boilerplate with mandatory merge fields
    // All templates use: {{school_name}}, {{student_name}}, {{certificate_no}},
    //                    {{issue_date}}, {{principal_name}}
    // -------------------------------------------------------------------------

    private function bonafideHtml(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 13pt; color: #222; }
  .header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 10px; margin-bottom: 20px; }
  .school-name { font-size: 20pt; font-weight: bold; }
  .cert-title { font-size: 16pt; font-weight: bold; text-transform: uppercase; margin: 20px 0; text-align: center; }
  .body-text { line-height: 2; text-align: justify; }
  .footer { margin-top: 60px; display: flex; justify-content: space-between; }
  .cert-no { font-size: 10pt; color: #666; }
</style>
</head>
<body>
  <div class="header">
    <div class="school-name">{{school_name}}</div>
  </div>

  <div class="cert-title">Bonafide Certificate</div>

  <p class="body-text">
    This is to certify that <strong>{{student_name}}</strong> is a bonafide student of this school.
    This certificate is issued as requested for the purpose as stated by the student.
  </p>

  <div class="footer">
    <div>
      <p class="cert-no">Certificate No: {{certificate_no}}</p>
      <p>Date: {{issue_date}}</p>
    </div>
    <div style="text-align: right;">
      <br><br>
      <p><strong>{{principal_name}}</strong></p>
      <p>Principal</p>
    </div>
  </div>
</body>
</html>
HTML;
    }

    private function tcHtml(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 12pt; color: #000; }
  .header { text-align: center; border-bottom: 3px double #000; padding-bottom: 10px; margin-bottom: 15px; }
  .school-name { font-size: 18pt; font-weight: bold; }
  .cert-title { font-size: 15pt; font-weight: bold; text-transform: uppercase; margin: 15px 0; text-align: center; letter-spacing: 2px; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 8px 4px; vertical-align: top; }
  td.label { width: 40%; font-weight: bold; }
  .footer { margin-top: 50px; text-align: right; }
  .cert-no { font-size: 10pt; color: #444; }
</style>
</head>
<body>
  <div class="header">
    <div class="school-name">{{school_name}}</div>
    <div style="font-size:11pt;">Transfer Certificate</div>
  </div>

  <div class="cert-title">Transfer Certificate</div>

  <table>
    <tr><td class="label">1. Name of Student</td><td>: {{student_name}}</td></tr>
    <tr><td class="label">2. Certificate Number</td><td>: {{certificate_no}}</td></tr>
    <tr><td class="label">3. Date of Issue</td><td>: {{issue_date}}</td></tr>
  </table>

  <div class="footer">
    <br><br>
    <p><strong>{{principal_name}}</strong></p>
    <p>Principal / Headmaster</p>
    <p class="cert-no">TC No: {{certificate_no}}</p>
  </div>
</body>
</html>
HTML;
    }

    private function characterHtml(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 13pt; color: #222; }
  .header { text-align: center; margin-bottom: 20px; }
  .school-name { font-size: 20pt; font-weight: bold; }
  .cert-title { font-size: 16pt; font-weight: bold; text-transform: uppercase; margin: 20px 0; text-align: center; }
  .body-text { line-height: 2; text-align: justify; }
  .footer { margin-top: 60px; display: flex; justify-content: space-between; }
  .cert-no { font-size: 10pt; color: #666; }
</style>
</head>
<body>
  <div class="header">
    <div class="school-name">{{school_name}}</div>
  </div>

  <div class="cert-title">Character Certificate</div>

  <p class="body-text">
    This is to certify that <strong>{{student_name}}</strong> has been a student of this institution.
    During the period of study, the student has maintained good character and conduct.
    This certificate is issued based on our records.
  </p>

  <div class="footer">
    <div>
      <p class="cert-no">Certificate No: {{certificate_no}}</p>
      <p>Date: {{issue_date}}</p>
    </div>
    <div style="text-align: right;">
      <br><br>
      <p><strong>{{principal_name}}</strong></p>
      <p>Principal</p>
    </div>
  </div>
</body>
</html>
HTML;
    }

    private function meritHtml(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 13pt; color: #222; text-align: center; }
  .school-name { font-size: 18pt; font-weight: bold; margin-bottom: 5px; }
  .cert-title { font-size: 22pt; font-weight: bold; color: #8B0000; margin: 25px 0 10px; }
  .subtitle { font-size: 14pt; margin-bottom: 25px; }
  .recipient { font-size: 18pt; font-weight: bold; border-bottom: 2px solid #8B0000; display: inline-block; padding-bottom: 5px; }
  .body-text { line-height: 2; margin: 20px auto; max-width: 80%; }
  .footer { margin-top: 50px; display: flex; justify-content: space-around; }
  .cert-no { font-size: 10pt; color: #666; margin-top: 20px; }
</style>
</head>
<body>
  <div class="school-name">{{school_name}}</div>
  <div class="cert-title">Certificate of Merit</div>
  <div class="subtitle">This certificate is proudly presented to</div>
  <div class="recipient">{{student_name}}</div>
  <p class="body-text">In recognition of outstanding academic achievement and dedication to excellence.</p>
  <div class="footer">
    <div>
      <p>Date: {{issue_date}}</p>
    </div>
    <div>
      <br>
      <p><strong>{{principal_name}}</strong></p>
      <p>Principal</p>
    </div>
  </div>
  <p class="cert-no">Certificate No: {{certificate_no}}</p>
</body>
</html>
HTML;
    }

    private function sportsHtml(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: DejaVu Sans, sans-serif; font-size: 13pt; color: #222; text-align: center; }
  .school-name { font-size: 18pt; font-weight: bold; margin-bottom: 5px; }
  .cert-title { font-size: 22pt; font-weight: bold; color: #1a5276; margin: 25px 0 10px; }
  .subtitle { font-size: 14pt; margin-bottom: 25px; }
  .recipient { font-size: 18pt; font-weight: bold; border-bottom: 2px solid #1a5276; display: inline-block; padding-bottom: 5px; }
  .body-text { line-height: 2; margin: 20px auto; max-width: 80%; }
  .footer { margin-top: 50px; display: flex; justify-content: space-around; }
  .cert-no { font-size: 10pt; color: #666; margin-top: 20px; }
</style>
</head>
<body>
  <div class="school-name">{{school_name}}</div>
  <div class="cert-title">Sports Certificate</div>
  <div class="subtitle">This certificate is proudly awarded to</div>
  <div class="recipient">{{student_name}}</div>
  <p class="body-text">In recognition of excellent performance and sportsmanship demonstrated throughout the academic year.</p>
  <div class="footer">
    <div>
      <p>Date: {{issue_date}}</p>
    </div>
    <div>
      <br>
      <p><strong>{{principal_name}}</strong></p>
      <p>Principal</p>
    </div>
  </div>
  <p class="cert-no">Certificate No: {{certificate_no}}</p>
</body>
</html>
HTML;
    }
}
