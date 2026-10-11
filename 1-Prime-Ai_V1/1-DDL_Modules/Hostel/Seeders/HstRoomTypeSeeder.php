<?php

namespace Database\Seeders\Tenant\Hostel;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * HstRoomTypeSeeder
 *
 * Seeds human-readable labels for the hst_rooms.room_type ENUM values
 * into sys_settings using the key pattern: hostel.room_type_labels.{type}
 *
 * These settings allow the UI to display custom labels, icons, and
 * descriptions for each room type without altering the ENUM definition.
 *
 * Copy to: database/seeders/tenant/Hostel/HstRoomTypeSeeder.php
 */
class HstRoomTypeSeeder extends Seeder
{
    /**
     * ENUM values from hst_rooms.room_type:
     * dormitory | private | semi-private | suite
     */
    private array $roomTypes = [
        'dormitory' => [
            'label'       => 'Dormitory',
            'description' => 'Shared room with multiple beds (6–12 students)',
            'icon'        => 'bed-multiple',
            'sort_order'  => 1,
        ],
        'private' => [
            'label'       => 'Private Room',
            'description' => 'Single-occupancy private room',
            'icon'        => 'bed-single',
            'sort_order'  => 2,
        ],
        'semi-private' => [
            'label'       => 'Semi-Private Room',
            'description' => 'Double-occupancy shared room (2 students)',
            'icon'        => 'bed-double',
            'sort_order'  => 3,
        ],
        'suite' => [
            'label'       => 'Suite',
            'description' => 'Premium room with attached amenities',
            'icon'        => 'star',
            'sort_order'  => 4,
        ],
    ];

    public function run(): void
    {
        foreach ($this->roomTypes as $type => $meta) {
            $key = "hostel.room_type_labels.{$type}";

            DB::table('sys_settings')->upsert(
                [
                    'key'         => $key,
                    'value'       => json_encode($meta),
                    'group'       => 'hostel',
                    'type'        => 'json',
                    'description' => "Hostel room type display config for: {$type}",
                    'is_active'   => 1,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ],
                ['key'],               // unique key for upsert
                ['value', 'updated_at'] // columns to update on conflict
            );
        }

        $this->command->info('HstRoomTypeSeeder: seeded ' . count($this->roomTypes) . ' room type labels into sys_settings.');
    }
}
