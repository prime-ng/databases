<?php

namespace Modules\BehaviouralAssessment\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BaCategorySeeder extends Seeder
{
    /**
     * Seed the 9 default behavioural categories (5 Positive + 4 Negative)
     * with all 58 criteria, verbatim from BehaviouralAssessment_v1.md Section 3.
     */
    public function run(): void
    {
        $now = now();
        $userId = 1; // System user

        $categories = $this->getCategoriesWithCriteria();

        foreach ($categories as $sortOrder => $category) {
            $criteriaCount = count($category['criteria']);
            $defaultWeight = $criteriaCount > 0 ? round(100 / $criteriaCount, 2) : 0;

            $categoryId = DB::table('ba_categories')->insertGetId([
                'parent_id'   => null,
                'name'        => $category['name'],
                'description' => $category['description'],
                'polarity'    => $category['polarity'],
                'weight'      => 100.00, // Equal weight across all categories by default
                'sort_order'  => $sortOrder + 1,
                'is_active'   => true,
                'created_by'  => $userId,
                'updated_by'  => $userId,
                'created_at'  => $now,
                'updated_at'  => $now,
            ]);

            foreach ($category['criteria'] as $criterionOrder => $criterionName) {
                DB::table('ba_criteria')->insert([
                    'category_id' => $categoryId,
                    'name'        => $criterionName,
                    'description' => null,
                    'weight'      => $defaultWeight,
                    'sort_order'  => $criterionOrder + 1,
                    'is_active'   => true,
                    'created_by'  => $userId,
                    'updated_by'  => $userId,
                    'created_at'  => $now,
                    'updated_at'  => $now,
                ]);
            }
        }
    }

    /**
     * Return the 9 categories with all 58 criteria.
     */
    private function getCategoriesWithCriteria(): array
    {
        return [
            // ── POSITIVE CATEGORIES (5) ──────────────────────────────────

            [
                'name'        => 'Classroom Engagement',
                'description' => 'Measures how actively and constructively a student participates in the learning environment.',
                'polarity'    => 'positive',
                'criteria'    => [
                    'Active participation in class discussions and oral activities',
                    'Asking thoughtful, relevant, and clarifying questions',
                    'Paying sustained attention to instructions, lessons, and demonstrations',
                    'Completing classwork, assignments, and homework on time and with care',
                    'Demonstrating effort, persistence, and resilience when facing academic challenges',
                    'Showing curiosity and initiative in exploring topics beyond the syllabus',
                    'Bringing required materials and being prepared for class',
                    'Responding constructively to teacher feedback and corrections',
                ],
            ],

            [
                'name'        => 'Respect and Responsibility',
                'description' => 'Evaluates a student\'s ability to treat others with dignity and take ownership of their actions.',
                'polarity'    => 'positive',
                'criteria'    => [
                    'Respecting teachers, peers, support staff, and visitors',
                    'Following school rules, classroom procedures, and safety guidelines',
                    'Taking responsibility for personal actions, mistakes, and belongings',
                    'Being courteous, polite, and using appropriate language at all times',
                    'Demonstrating honesty and integrity in all interactions',
                    'Respecting school property, shared resources, and the environment',
                    'Being punctual to school and classes',
                    'Maintaining personal hygiene and adhering to the dress code',
                ],
            ],

            [
                'name'        => 'Cooperation and Collaboration',
                'description' => 'Assesses teamwork skills and the ability to work harmoniously with others.',
                'polarity'    => 'positive',
                'criteria'    => [
                    'Working effectively and equitably in group assignments and projects',
                    'Helping classmates who are struggling without being asked',
                    'Sharing ideas, perspectives, and resources respectfully',
                    'Actively participating in school events, assemblies, and extracurricular activities',
                    'Accepting and respecting diverse viewpoints and cultural differences',
                    'Mediating or de-escalating minor peer conflicts constructively',
                    'Contributing to a positive classroom atmosphere',
                ],
            ],

            [
                'name'        => 'Emotional and Social Development',
                'description' => 'Tracks the student\'s emotional intelligence, self-regulation, and interpersonal maturity.',
                'polarity'    => 'positive',
                'criteria'    => [
                    'Demonstrating empathy and compassion towards peers',
                    'Managing emotions appropriately under stress or frustration',
                    'Accepting constructive criticism gracefully',
                    'Showing self-confidence without arrogance',
                    'Resolving personal conflicts through dialogue rather than aggression',
                    'Demonstrating patience and turn-taking in conversations and activities',
                ],
            ],

            [
                'name'        => 'Leadership and Initiative',
                'description' => 'Recognises students who proactively contribute to school life and inspire others.',
                'polarity'    => 'positive',
                'criteria'    => [
                    'Volunteering for classroom or school responsibilities',
                    'Taking initiative to organise or lead group activities',
                    'Mentoring or tutoring fellow students',
                    'Demonstrating good sportsmanship in competitions',
                    'Representing school values in external events or inter-school activities',
                    'Proposing constructive ideas for class or school improvement',
                ],
            ],

            // ── NEGATIVE CATEGORIES (4) ──────────────────────────────────

            [
                'name'        => 'Disruptive Behaviours',
                'description' => 'Records behaviours that hinder the learning environment for self or others.',
                'polarity'    => 'negative',
                'criteria'    => [
                    'Talking out of turn or disrupting ongoing lessons',
                    'Creating unnecessary noise, distractions, or disturbances',
                    'Not following instructions, rules, or safety procedures',
                    'Being consistently off-task, inattentive, or not participating',
                    'Using mobile phones or electronic devices without permission',
                    'Leaving the classroom without permission',
                    'Eating or drinking in class without permission',
                ],
            ],

            [
                'name'        => 'Aggressive or Bullying Behaviours',
                'description' => 'Captures serious behavioural concerns involving harm or intimidation.',
                'polarity'    => 'negative',
                'criteria'    => [
                    'Physical aggression (hitting, pushing, fighting) towards others',
                    'Verbal aggression (shouting, threatening, using abusive language)',
                    'Bullying or teasing other students (physical, verbal, or cyber)',
                    'Harassment, discrimination, or exclusion based on caste, religion, gender, or appearance',
                    'Intimidating, coercing, or blackmailing peers',
                    'Damaging or stealing school or peer property',
                ],
            ],

            [
                'name'        => 'Academic Misconduct',
                'description' => 'Tracks dishonesty and non-compliance in academic contexts.',
                'polarity'    => 'negative',
                'criteria'    => [
                    'Cheating during exams or assessments',
                    'Plagiarism or copying homework/assignments',
                    'Repeatedly not completing or submitting assignments',
                    'Forging signatures or tampering with academic records',
                    'Disrespectful or defiant behaviour towards teachers during instruction',
                    'Providing false information or making dishonest excuses',
                ],
            ],

            [
                'name'        => 'Health and Safety Violations',
                'description' => 'Behaviours that endanger physical safety on school premises.',
                'polarity'    => 'negative',
                'criteria'    => [
                    'Engaging in dangerous play or stunts on school premises',
                    'Possession or use of prohibited substances on campus',
                    'Violating laboratory, workshop, or sports safety rules',
                    'Encouraging or daring peers to engage in risky behaviours',
                ],
            ],
        ];
    }
}
