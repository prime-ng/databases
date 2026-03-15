<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Modules\SmartTimetable\Models\ClassGroupJnt;

class ClassSubgroupSeeder extends Seeder
{

    private $subgroupTypes = [
        'OPTIONAL_SUBJECT',
        'HOBBY',
        'SKILL',
        'LANGUAGE',
        'STREAM',
        'ACTIVITY',
        'SPORTS',
        'OTHER'
    ];

    private $hobbySubgroups = [
        'Music Club',
        'Dance Club',
        'Art Club',
        'Drama Club',
        'Photography Club',
        'Chess Club',
        'Robotics Club',
        'Science Club',
        'Math Club',
        'Debate Club',
        'Creative Writing',
        'Yoga Club'
    ];

    private $languageSubgroups = [
        'French Beginners',
        'French Advanced',
        'German Basics',
        'Spanish Conversation',
        'Sanskrit Scholars',
        'English Literature'
    ];

    private $sportsSubgroups = [
        'Basketball Team',
        'Football Team',
        'Cricket Team',
        'Athletics',
        'Swimming',
        'Badminton',
        'Table Tennis'
    ];

    private $skillSubgroups = [
        'Computer Programming',
        'Graphic Design',
        'Public Speaking',
        'Leadership Skills',
        'Time Management',
        'Financial Literacy'
    ];

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Clear existing data (optional)
        // DB::table('tt_class_subgroup_members')->truncate();
        // DB::table('tt_class_subgroups')->truncate();

        // Check if class groups exist
        $classGroups = ClassGroupJnt::where('is_active', true)
            ->get();

        if ($classGroups->isEmpty()) {
            $this->command->warn('No active class groups found. Please run TtClassGroupsJntSeeder first.');
            return;
        }

        // Check if we already have data
        $existingSubgroups = DB::table('tt_class_subgroups')->count();
        $existingMembers = DB::table('tt_class_subgroup_members')->count();

        if ($existingSubgroups > 0 || $existingMembers > 0) {
            $this->command->info('Class subgroups/members already exist. Use --fresh to regenerate.');
            return;
        }

        $subgroups = [];
        $members = [];
        $now = now();
        $subgroupCounter = 0;

        foreach ($classGroups as $group) {
            // For each class group, create 1-3 subgroups
            $numSubgroups = rand(1, 3);

            for ($i = 1; $i <= $numSubgroups; $i++) {
                $subgroupCounter++;

                // Generate subgroup data
                $subgroupType = $this->getRandomSubgroupType($group);
                $subgroupName = $this->generateSubgroupName($group, $subgroupType, $i);
                $subgroupCode = $this->generateSubgroupCode($group, $subgroupType, $i);

                // Determine student count ranges based on type
                $studentCounts = $this->getStudentCountsByType($subgroupType);

                // Determine sharing settings
                $sharingSettings = $this->getSharingSettings($subgroupType);

                // Create subgroup entry
                $subgroups[] = [
                    'code' => $subgroupCode,
                    'name' => $subgroupName,
                    'description' => $this->generateDescription($group, $subgroupType, $i),
                    'class_group_id' => $group->id,
                    'subgroup_type' => $subgroupType,
                    'student_count' => $studentCounts['count'],
                    'min_students' => $studentCounts['min'],
                    'max_students' => $studentCounts['max'],
                    'is_shared_across_sections' => $sharingSettings['across_sections'],
                    'is_shared_across_classes' => $sharingSettings['across_classes'],
                    'is_active' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                // Store the ID we'll use for this subgroup
                $subgroupId = $subgroupCounter; // We'll use the counter as temporary ID

                // Generate member entries for this subgroup
                $memberEntries = $this->generateMemberEntries(
                    $group,
                    $subgroupId,
                    $sharingSettings
                );

                $members = array_merge($members, $memberEntries);
            }
        }

        // Insert subgroups first
        $this->command->info("Inserting " . count($subgroups) . " subgroups...");
        foreach (array_chunk($subgroups, 50) as $batch) {
            DB::table('tt_class_subgroups')->insert($batch);
        }

        // Now get the actual inserted IDs to update member entries
        $insertedSubgroups = DB::table('tt_class_subgroups')
            ->orderBy('id')
            ->pluck('id')
            ->toArray();

        // Update member entries with actual subgroup IDs
        $this->command->info("Updating member entries with actual IDs...");
        foreach ($members as $index => $member) {
            // Map temporary ID to actual ID
            $tempId = $member['class_subgroup_id'];
            if (isset($insertedSubgroups[$tempId - 1])) {
                $members[$index]['class_subgroup_id'] = $insertedSubgroups[$tempId - 1];
            }
        }

        // Insert members
        $this->command->info("Inserting " . count($members) . " member entries...");
        foreach (array_chunk($members, 50) as $batch) {
            try {
                DB::table('tt_class_subgroup_members')->insert($batch);
            } catch (\Exception $e) {
                // Skip duplicates
                $this->command->warn("Skipped duplicate member entry: " . $e->getMessage());
                continue;
            }
        }

        $this->command->info("✅ Created " . count($subgroups) . " subgroups and " . count($members) . " member entries.");
    }

    /**
     * Get random subgroup type based on class group
     */
    private function getRandomSubgroupType($group): string
    {
        // Weighted probabilities for different types
        $weights = [
            'HOBBY' => 25,
            'LANGUAGE' => 20,
            'SPORTS' => 15,
            'SKILL' => 15,
            'OPTIONAL_SUBJECT' => 10,
            'ACTIVITY' => 10,
            'STREAM' => 5,
            'OTHER' => 5,
        ];

        $total = array_sum($weights);
        $rand = rand(1, $total);
        $current = 0;

        foreach ($weights as $type => $weight) {
            $current += $weight;
            if ($rand <= $current) {
                return $type;
            }
        }

        return 'OTHER';
    }

    /**
     * Generate subgroup name
     */
    private function generateSubgroupName($group, string $type, int $index): string
    {
        $className = $group->name;
        $typeName = str_replace('_', ' ', $type);

        switch ($type) {
            case 'HOBBY':
                $base = $this->hobbySubgroups[array_rand($this->hobbySubgroups)];
                break;
            case 'LANGUAGE':
                $base = $this->languageSubgroups[array_rand($this->languageSubgroups)];
                break;
            case 'SPORTS':
                $base = $this->sportsSubgroups[array_rand($this->sportsSubgroups)];
                break;
            case 'SKILL':
                $base = $this->skillSubgroups[array_rand($this->skillSubgroups)];
                break;
            case 'OPTIONAL_SUBJECT':
                $base = 'Optional ' . $this->getSubjectFromGroup($group) . ' Group';
                break;
            default:
                $base = ucfirst(strtolower($type)) . ' Group ' . $index;
                break;
        }

        return "{$className} - {$base}";
    }

    /**
     * Generate subgroup code
     */
    private function generateSubgroupCode($group, string $type, int $index): string
    {
        $groupCode = $group->code;
        $typePrefix = substr($type, 0, 3);
        return "{$groupCode}_{$typePrefix}_{$index}";
    }

    /**
     * Generate description
     */
    private function generateDescription($group, string $type, int $index): string
    {
        $className = $group->name;
        $typeName = str_replace('_', ' ', strtolower($type));

        $descriptions = [
            "Special {$typeName} group for {$className} students.",
            "This subgroup focuses on {$typeName} development within {$className}.",
            "A dedicated group for {$className} students interested in {$typeName}.",
            "Enhanced learning group for {$typeName} in {$className}.",
            "Supplementary {$typeName} activities for {$className} class."
        ];

        return $descriptions[array_rand($descriptions)];
    }

    /**
     * Get student counts based on subgroup type
     */
    private function getStudentCountsByType(string $type): array
    {
        switch ($type) {
            case 'SPORTS':
                $count = rand(10, 20);
                return [
                    'count' => $count,
                    'min' => 8,
                    'max' => 25
                ];

            case 'HOBBY':
            case 'SKILL':
                $count = rand(12, 25);
                return [
                    'count' => $count,
                    'min' => 10,
                    'max' => 30
                ];

            case 'LANGUAGE':
            case 'OPTIONAL_SUBJECT':
                $count = rand(15, 30);
                return [
                    'count' => $count,
                    'min' => 12,
                    'max' => 35
                ];

            case 'ACTIVITY':
                $count = rand(20, 40);
                return [
                    'count' => $count,
                    'min' => 15,
                    'max' => 45
                ];

            default:
                $count = rand(10, 25);
                return [
                    'count' => $count,
                    'min' => 8,
                    'max' => 30
                ];
        }
    }

    /**
     * Get sharing settings based on type
     */
    private function getSharingSettings(string $type): array
    {
        // Some subgroup types are more likely to be shared
        switch ($type) {
            case 'SPORTS':
                // Sports teams often combine sections
                return [
                    'across_sections' => rand(0, 1) == 1, // 50% chance
                    'across_classes' => false
                ];

            case 'HOBBY':
                // Hobby clubs might combine sections
                return [
                    'across_sections' => rand(0, 3) == 1, // 25% chance
                    'across_classes' => false
                ];

            case 'LANGUAGE':
                // Language groups might combine classes
                return [
                    'across_sections' => true,
                    'across_classes' => rand(0, 3) == 1 // 25% chance
                ];

            default:
                return [
                    'across_sections' => false,
                    'across_classes' => false
                ];
        }
    }

    /**
     * Generate member entries for a subgroup
     */
    private function generateMemberEntries($group, int $subgroupId, array $sharingSettings): array
    {
        $entries = [];
        $now = now();

        // Primary entry (always included)
        $entries[] = [
            'class_subgroup_id' => $subgroupId,
            'class_id' => $group->class_id,
            'section_id' => $group->section_id,
            'is_primary' => true,
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ];

        // Check if subgroup is shared across sections
        if ($sharingSettings['across_sections']) {
            // Get other sections in the same class
            $otherSections = DB::table('tt_class_groups_jnt')
                ->where('class_id', $group->class_id)
                ->where('section_id', '!=', $group->section_id)
                ->where('is_active', true)
                ->pluck('section_id')
                ->unique()
                ->toArray();

            // Add 1-2 other sections
            $numSections = min(rand(1, 2), count($otherSections));

            if ($numSections > 0) {
                $selectedIndices = array_rand($otherSections, $numSections);

                if (!is_array($selectedIndices)) {
                    $selectedIndices = [$selectedIndices];
                }

                foreach ($selectedIndices as $index) {
                    $entries[] = [
                        'class_subgroup_id' => $subgroupId,
                        'class_id' => $group->class_id,
                        'section_id' => $otherSections[$index],
                        'is_primary' => false,
                        'is_active' => true,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
            }
        }

        // Check if subgroup is shared across classes
        if ($sharingSettings['across_classes']) {
            // Get other classes (1-2 other classes)
            $otherClasses = DB::table('tt_class_groups_jnt')
                ->where('class_id', '!=', $group->class_id)
                ->where('is_active', true)
                ->pluck('class_id')
                ->unique()
                ->toArray();

            $numClasses = min(rand(1, 2), count($otherClasses));

            if ($numClasses > 0) {
                $selectedIndices = array_rand($otherClasses, $numClasses);

                if (!is_array($selectedIndices)) {
                    $selectedIndices = [$selectedIndices];
                }

                foreach ($selectedIndices as $index) {
                    $entries[] = [
                        'class_subgroup_id' => $subgroupId,
                        'class_id' => $otherClasses[$index],
                        'section_id' => null, // Shared across classes often means all sections
                        'is_primary' => false,
                        'is_active' => true,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
            }
        }

        return $entries;
    }

    /**
     * Extract subject from group name for optional subjects
     */
    private function getSubjectFromGroup($group): string
    {
        $name = $group->name;

        // Try to extract subject from name
        $subjects = [
            'English',
            'Hindi',
            'Maths',
            'Social Science',
            'Sanskrit',
            'Science',
            'Computer Science',
            'French',
            'Library',
            'Games',
        ];

        foreach ($subjects as $subject) {
            if (stripos($name, $subject) !== false) {
                return $subject;
            }
        }

        return 'Subject';
    }
}