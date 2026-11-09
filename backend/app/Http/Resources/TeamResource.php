<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TeamResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'color' => $this->color,
            'owner_id' => $this->owner_id,
            'my_role' => $this->pivot?->role ?? $this->roleOf($request->user()),
            'members_count' => $this->whenCounted('members'),
            'open_tasks_count' => $this->whenCounted('tasks'),
            'members' => MemberResource::collection($this->whenLoaded('members')),
        ];
    }
}
