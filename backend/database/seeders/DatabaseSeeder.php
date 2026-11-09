<?php

namespace Database\Seeders;

use App\Models\Team;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $demo = User::factory()->create(['name' => 'Demo User', 'email' => 'demo@taskflow.test']);
        $sara = User::factory()->create(['name' => 'Sara Ali', 'email' => 'sara@taskflow.test']);
        $omar = User::factory()->create(['name' => 'Omar Khaled', 'email' => 'omar@taskflow.test']);

        $mobile = Team::create(['name' => 'Mobile Team', 'description' => 'Flutter app for the delivery startup', 'color' => '#4F46E5', 'owner_id' => $demo->id]);
        $mobile->members()->attach([$demo->id => ['role' => 'owner'], $sara->id => ['role' => 'admin'], $omar->id => ['role' => 'member']]);

        $web = Team::create(['name' => 'Backend API', 'description' => 'Laravel services and integrations', 'color' => '#059669', 'owner_id' => $sara->id]);
        $web->members()->attach([$sara->id => ['role' => 'owner'], $demo->id => ['role' => 'member']]);

        $tasks = [
            [$mobile, 'Design onboarding screens', 'done', 'medium', -6, $sara],
            [$mobile, 'Implement login with token refresh', 'review', 'high', 1, $demo],
            [$mobile, 'Push notifications with FCM', 'in_progress', 'high', 3, $omar],
            [$mobile, 'Order tracking map screen', 'todo', 'urgent', -1, $demo],
            [$mobile, 'Dark mode support', 'todo', 'low', 14, null],
            [$mobile, 'Write widget tests for cart', 'todo', 'medium', 6, $omar],
            [$web, 'Payment gateway webhook', 'in_progress', 'urgent', 2, $sara],
            [$web, 'Rate limiting for public endpoints', 'todo', 'medium', 5, $demo],
            [$web, 'Daily sales report job', 'done', 'low', -3, $demo],
        ];

        foreach ($tasks as $i => [$team, $title, $status, $priority, $dueIn, $assignee]) {
            $task = $team->tasks()->create([
                'creator_id' => $team->owner_id,
                'assignee_id' => $assignee?->id,
                'title' => $title,
                'description' => "Acceptance criteria for \"{$title}\" are in the project brief.",
                'status' => $status,
                'priority' => $priority,
                'due_date' => today()->addDays($dueIn),
                'position' => $i,
            ]);

            if ($status === 'review') {
                $task->comments()->create(['user_id' => $sara->id, 'body' => 'Looks good. Can you add a test for expired tokens?']);
            }
        }
    }
}
