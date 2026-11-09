# ✅ TaskFlow: Team Task Manager

A full-stack team collaboration app: a **Flutter** Kanban app backed by a **Laravel 12 REST API**.

Teams plan their work on a drag-and-drop board, assign tasks to teammates, set priorities and due dates, discuss work in comments, and see a personal dashboard of what's due.

## Features

**Mobile app (Flutter)**
- Personal dashboard: open, overdue, due-this-week, and done-this-week counts, plus upcoming tasks
- Teams list with color labels, member counts, and open-task counts
- **Kanban board** (To do → In progress → Review → Done). Long-press and drag a card to move it.
- "Only my tasks" filter
- Create and edit tasks in a bottom sheet: status, priority, assignee, and due date
- Task details with a quick status switcher and threaded comments
- Member management: add people by email as admin or member, and remove them

**Backend (Laravel)**
- Sanctum token auth
- Role-based access per team: **owner / admin / member**
- Non-members get a `404` for team data, so the API never reveals that a team exists
- Tasks can only be assigned to team members
- `move` endpoint re-orders the column positions inside a transaction
- `completed_at` is set and cleared automatically through a model event
- Dashboard endpoint that aggregates tasks across all your teams
- Removing a member unassigns their tasks
- Feature tests for roles, assignment rules, privacy, and moving tasks

## Tech stack

| Layer | Tech |
|---|---|
| Mobile | Flutter 3, Dart, Provider, http, shared_preferences, intl |
| API | PHP 8.2+, Laravel 12, Sanctum |
| Database | SQLite (dev), MySQL / PostgreSQL ready |
| Tests | PHPUnit, flutter_test |

## Getting started

### Backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve
```
Demo accounts (password: `password`): `demo@taskflow.test`, `sara@taskflow.test`, `omar@taskflow.test`

Run tests: `php artisan test`

### Mobile
```bash
cd mobile
flutter create . --project-name taskflow --platforms android,ios
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
```

## API endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register`, `/api/auth/login` | Auth |
| GET | `/api/dashboard` | My stats and upcoming tasks |
| GET / POST | `/api/teams` | My teams, or create a team |
| GET / PUT / DELETE | `/api/teams/{team}` | Team details, update, or delete |
| POST | `/api/teams/{team}/members` | Add a member by email |
| DELETE | `/api/teams/{team}/members/{user}` | Remove a member |
| GET | `/api/teams/{team}/tasks?status=&priority=&assignee=me&q=` | Team tasks |
| POST | `/api/teams/{team}/tasks` | Create a task |
| GET / PATCH / DELETE | `/api/tasks/{task}` | Task details, update, or delete |
| PATCH | `/api/tasks/{task}/move` | Move to a status and position |
| POST | `/api/tasks/{task}/comments` | Add a comment |

All endpoints except auth require `Authorization: Bearer <token>`.

## License

MIT
