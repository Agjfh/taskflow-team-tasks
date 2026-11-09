<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TaskResource;
use App\Models\Task;
use App\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TaskController extends Controller
{
    public function index(Request $request, Team $team): AnonymousResourceCollection
    {
        $this->ensureMember($request, $team);

        $request->validate([
            'status' => ['nullable', Rule::in(Task::STATUSES)],
            'assignee' => ['nullable'],
            'priority' => ['nullable', Rule::in(Task::PRIORITIES)],
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        $tasks = $team->tasks()
            ->with(['assignee', 'creator'])
            ->withCount('comments')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->priority, fn ($q, $p) => $q->where('priority', $p))
            ->when($request->assignee === 'me', fn ($q) => $q->where('assignee_id', $request->user()->id))
            ->when(is_numeric($request->assignee), fn ($q) => $q->where('assignee_id', $request->assignee))
            ->when($request->q, fn ($q, $term) => $q->where('title', 'like', "%{$term}%"))
            ->orderBy('status')
            ->orderBy('position')
            ->get();

        return TaskResource::collection($tasks);
    }

    public function store(Request $request, Team $team): JsonResponse
    {
        $this->ensureMember($request, $team);
        $data = $this->validated($request, $team);

        $data['status'] ??= 'todo';
        $data['position'] = (int) $team->tasks()->where('status', $data['status'])->max('position') + 1;

        $task = $team->tasks()->create($data + ['creator_id' => $request->user()->id]);

        return (new TaskResource($task->load(['assignee', 'creator'])))->response()->setStatusCode(201);
    }

    public function show(Request $request, Task $task): TaskResource
    {
        $this->ensureMember($request, $task->team);

        return new TaskResource($task->load(['assignee', 'creator', 'comments.user']));
    }

    public function update(Request $request, Task $task): TaskResource
    {
        $this->ensureMember($request, $task->team);

        $task->update($this->validated($request, $task->team, partial: true));

        return new TaskResource($task->load(['assignee', 'creator', 'comments.user']));
    }

    /** Moves a task to a column (status) and position, re-ordering the others. */
    public function move(Request $request, Task $task): TaskResource
    {
        $this->ensureMember($request, $task->team);

        $data = $request->validate([
            'status' => ['required', Rule::in(Task::STATUSES)],
            'position' => ['nullable', 'integer', 'min:0'],
        ]);

        DB::transaction(function () use ($task, $data) {
            $ids = Task::where('team_id', $task->team_id)
                ->where('status', $data['status'])
                ->whereKeyNot($task->id)
                ->orderBy('position')
                ->pluck('id')
                ->all();

            $position = min($data['position'] ?? count($ids), count($ids));
            array_splice($ids, $position, 0, [$task->id]);

            $task->update(['status' => $data['status']]);
            foreach ($ids as $index => $id) {
                Task::whereKey($id)->update(['position' => $index]);
            }
        });

        return new TaskResource($task->fresh(['assignee', 'creator']));
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        $team = $task->team;
        $this->ensureMember($request, $team);
        abort_unless($task->creator_id === $request->user()->id || $team->canManage($request->user()), 403);

        $task->delete();

        return response()->json(null, 204);
    }

    public function comment(Request $request, Task $task): JsonResponse
    {
        $this->ensureMember($request, $task->team);
        $data = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        $task->comments()->create($data + ['user_id' => $request->user()->id]);

        return (new TaskResource($task->load(['assignee', 'creator', 'comments.user'])))
            ->response()->setStatusCode(201);
    }

    /** Overview for the signed-in user across all their teams. */
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();
        $teamIds = $user->teams()->pluck('teams.id');
        $mine = Task::whereIn('team_id', $teamIds)->where('assignee_id', $user->id);

        return response()->json([
            'assigned_open' => (clone $mine)->where('status', '!=', 'done')->count(),
            'overdue' => (clone $mine)->overdue()->count(),
            'due_this_week' => (clone $mine)->where('status', '!=', 'done')
                ->whereBetween('due_date', [today(), today()->addDays(7)])->count(),
            'completed_this_week' => (clone $mine)->where('completed_at', '>=', now()->startOfWeek())->count(),
            'upcoming' => TaskResource::collection(
                (clone $mine)->where('status', '!=', 'done')
                    ->with(['assignee', 'creator'])
                    ->orderByRaw('due_date IS NULL, due_date')
                    ->limit(10)
                    ->get()
            ),
        ]);
    }

    private function validated(Request $request, Team $team, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        $data = $request->validate([
            'title' => [$required, 'string', 'max:200'],
            'description' => ['nullable', 'string', 'max:5000'],
            'status' => ['sometimes', Rule::in(Task::STATUSES)],
            'priority' => ['sometimes', Rule::in(Task::PRIORITIES)],
            'due_date' => ['nullable', 'date'],
            'assignee_id' => ['nullable', 'integer'],
        ]);

        if (! empty($data['assignee_id'])) {
            abort_unless(
                $team->members()->where('users.id', $data['assignee_id'])->exists(),
                422,
                'Tasks can only be assigned to team members.'
            );
        }

        return $data;
    }

    private function ensureMember(Request $request, Team $team): void
    {
        abort_unless($team->hasMember($request->user()), 404);
    }
}
