<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RoomUnavaliableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | 1. Buildings (2)
        |--------------------------------------------------------------------------
        */

        $buildingIds = [];

        $buildingIds[] = DB::table('sch_buildings')->insertGetId([
            'code' => 'A1',
            'short_name' => 'Main',
            'name' => 'Main Building',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $buildingIds[] = DB::table('sch_buildings')->insertGetId([
            'code' => 'B1',
            'short_name' => 'Annex',
            'name' => 'Annex Building',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | 2. Room Types (2)
        |--------------------------------------------------------------------------
        */

        $roomTypeIds = [];

        $roomTypeIds[] = DB::table('sch_rooms_type')->insertGetId([
            'code' => 'CLS',
            'short_name' => 'Class',
            'name' => 'Classroom',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $roomTypeIds[] = DB::table('sch_rooms_type')->insertGetId([
            'code' => 'LAB',
            'short_name' => 'Lab',
            'name' => 'Laboratory',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | 3. Rooms (2)
        |--------------------------------------------------------------------------
        */

        $roomIds = [];

        $roomIds[] = DB::table('sch_rooms')->insertGetId([
            'building_id' => $buildingIds[0],
            'room_type_id' => $roomTypeIds[0],
            'code' => 'A1-101',
            'short_name' => 'R101',
            'name' => 'Room 101',
            'capacity' => 40,
            'max_limit' => 45,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $roomIds[] = DB::table('sch_rooms')->insertGetId([
            'building_id' => $buildingIds[1],
            'room_type_id' => $roomTypeIds[1],
            'code' => 'B1-L01',
            'short_name' => 'Lab1',
            'name' => 'Physics Lab',
            'capacity' => 30,
            'max_limit' => 35,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | 4. Constraints (2)
        |--------------------------------------------------------------------------
        */

        $academicSessionId = DB::connection('global_master_mysql')
            ->table('glb_academic_sessions')
            ->value('id');

        $constraintIds = [];

        $constraintIds[] = DB::table('tt_constraints')->insertGetId([
            'uuid' => random_bytes(16),
            'constraint_type_id' => 1,
            'name' => 'Room cleaning',
            'description' => 'Weekly cleaning constraint',
            'academic_session_id' => $academicSessionId,
            'target_type' => 'ROOM',
            'target_id' => $roomIds[0],
            'is_hard' => true,
            'weight' => 100,
            'params_json' => json_encode([]),
            'status' => 'ACTIVE',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $constraintIds[] = DB::table('tt_constraints')->insertGetId([
            'uuid' => random_bytes(16),
            'constraint_type_id' => 1,
            'name' => 'Lab maintenance',
            'description' => 'Monthly lab maintenance',
            'academic_session_id' => $academicSessionId,
            'target_type' => 'ROOM',
            'target_id' => $roomIds[1],
            'is_hard' => true,
            'weight' => 100,
            'params_json' => json_encode([]),
            'status' => 'ACTIVE',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | 5. Room Unavailables (2)
        |--------------------------------------------------------------------------
        */

        DB::table('tt_room_unavailables')->insert([
            [
                'room_id' => $roomIds[0],
                'constraint_id' => $constraintIds[0],
                'day_of_week' => 1, // Monday
                'period_ord' => 1,
                'reason' => 'Weekly cleaning',
                'is_recurring' => true,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'room_id' => $roomIds[1],
                'constraint_id' => $constraintIds[1],
                'day_of_week' => 3, // Wednesday
                'period_ord' => 4,
                'reason' => 'Lab maintenance',
                'is_recurring' => true,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
