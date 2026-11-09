<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskTest extends TestCase
{
    use RefreshDatabase;

    private function teamWithOwner(): array
    {
        $owner = User::factory()->create();
        $teamId = $this->actingAs($owner)->postJson('/api/teams', ['name' => 'Mobile'])->json('id');

        return [Team::find($teamId), $owner];
    }

    public function test_creator_becomes_team_owner(): void
    {
        [$team, $owner] = $this->teamWithOwner();

        $this->assertSame('owner', $team->roleOf($owner));
    }

    public function test_owner_can_add_member_and_assign_task(): void
    {
        [$team, $owner] = $this->teamWithOwner();
        $member = User::factory()->create(['email' => 'sara@example.com']);

        $this->actingAs($owner)->postJson("/api/teams/{$team->id}/members", ['email' => 'sara@example.com'])
            ->assertCreated();

        $this->actingAs($owner)->postJson("/api/teams/{$team->id}/tasks", [
            'title' => 'Build login screen',
            'assignee_id' => $member->id,
            'priority' => 'high',
        ])->assertCreated()->assertJsonPath('assignee.id', $member->id);
    }

    public function test_cannot_assign_task_to_non_member(): void
    {
        [$team, $owner] = $this->teamWithOwner();
        $stranger = User::factory()->create();

        $this->actingAs($owner)->postJson("/api/teams/{$team->id}/tasks", [
            'title' => 'Secret task',
            'assignee_id' => $stranger->id,
        ])->assertUnprocessable();
    }

    public function test_non_members_cannot_see_team_tasks(): void
    {
        [$team] = $this->teamWithOwner();

        $this->actingAs(User::factory()->create())
            ->getJson("/api/teams/{$team->id}/tasks")
            ->assertNotFound();
    }

    public function test_moving_task_to_done_sets_completed_at_and_reorders(): void
    {
        [$team, $owner] = $this->teamWithOwner();
        $a = $this->actingAs($owner)->postJson("/api/teams/{$team->id}/tasks", ['title' => 'A', 'status' => 'done'])->json('id');
        $b = $this->actingAs($owner)->postJson("/api/teams/{$team->id}/tasks", ['title' => 'B'])->json('id');

        $this->actingAs($owner)->patchJson("/api/tasks/{$b}/move", ['status' => 'done', 'position' => 0])
            ->assertOk()
            ->assertJsonPath('status', 'done')
            ->assertJsonPath('position', 0);

        $this->assertNotNull(\App\Models\Task::find($b)->completed_at);
        $this->assertSame(1, \App\Models\Task::find($a)->position);
    }

    public function test_members_cannot_add_other_members(): void
    {
        [$team, $owner] = $this->teamWithOwner();
        $member = User::factory()->create();
        $team->members()->attach($member->id, ['role' => 'member']);
        User::factory()->create(['email' => 'new@example.com']);

        $this->actingAs($member)->postJson("/api/teams/{$team->id}/members", ['email' => 'new@example.com'])
            ->assertForbidden();
    }
}
