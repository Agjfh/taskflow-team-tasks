<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\MemberResource;
use App\Http\Resources\TeamResource;
use App\Models\Team;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TeamController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $teams = $request->user()->teams()
            ->withCount(['members', 'tasks' => fn ($q) => $q->where('status', '!=', 'done')])
            ->orderBy('name')
            ->get();

        return TeamResource::collection($teams);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
            'color' => ['nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
        ]);

        $team = DB::transaction(function () use ($data, $request) {
            $team = Team::create($data + ['owner_id' => $request->user()->id]);
            $team->members()->attach($request->user()->id, ['role' => 'owner']);

            return $team;
        });

        return (new TeamResource($team->load('members')))->response()->setStatusCode(201);
    }

    public function show(Request $request, Team $team): TeamResource
    {
        $this->ensureMember($request, $team);

        return new TeamResource($team->load('members'));
    }

    public function update(Request $request, Team $team): TeamResource
    {
        $this->ensureManager($request, $team);

        $team->update($request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
            'color' => ['sometimes', 'regex:/^#[0-9A-Fa-f]{6}$/'],
        ]));

        return new TeamResource($team->load('members'));
    }

    public function destroy(Request $request, Team $team): JsonResponse
    {
        abort_unless($team->owner_id === $request->user()->id, 403, 'Only the owner can delete this team.');
        $team->delete();

        return response()->json(null, 204);
    }

    public function addMember(Request $request, Team $team): JsonResponse
    {
        $this->ensureManager($request, $team);

        $data = $request->validate([
            'email' => ['required', 'email', 'exists:users,email'],
            'role' => ['nullable', Rule::in(['admin', 'member'])],
        ], ['email.exists' => 'No user is registered with this email yet.']);

        $user = User::where('email', $data['email'])->firstOrFail();
        abort_if($team->hasMember($user), 422, 'This user is already in the team.');

        $team->members()->attach($user->id, ['role' => $data['role'] ?? 'member']);

        return response()->json(
            MemberResource::collection($team->members()->get()),
            201
        );
    }

    public function removeMember(Request $request, Team $team, User $user): JsonResponse
    {
        $isSelf = $user->id === $request->user()->id;
        abort_unless($isSelf || $team->canManage($request->user()), 403);
        abort_if($user->id === $team->owner_id, 422, 'The owner cannot be removed from the team.');

        $team->members()->detach($user->id);
        $team->tasks()->where('assignee_id', $user->id)->update(['assignee_id' => null]);

        return response()->json(MemberResource::collection($team->members()->get()));
    }

    private function ensureMember(Request $request, Team $team): void
    {
        abort_unless($team->hasMember($request->user()), 404);
    }

    private function ensureManager(Request $request, Team $team): void
    {
        $this->ensureMember($request, $team);
        abort_unless($team->canManage($request->user()), 403, 'Only team owners and admins can do this.');
    }
}
