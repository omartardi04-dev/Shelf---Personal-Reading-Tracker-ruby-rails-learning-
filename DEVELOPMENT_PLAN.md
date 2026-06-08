# Shelf — Development Plan & Learning Checklist

A personal reading tracker built to learn **Ruby** and **Ruby on Rails** (Rails 8.1, Ruby 3.4.6).

This document orders the work the way a Rails app is naturally built: **data layer first, then authentication, then the request/response layer (controllers + views), then refinement (queries, assets, API)**. Tackle one task at a time, top to bottom. Each task lists the Ruby/Rails concepts it exercises so you can read further on your own.

---

## The Domain (reference)

Three models:

| Model    | Fields                                                   |
|----------|----------------------------------------------------------|
| `User`   | name, email, password_digest                             |
| `Book`   | title, author, description, status (enum), user_id       |
| `Review` | content, rating, user_id, book_id                        |

Relationships:
- `User` **has many** `Book`s and `Review`s
- `Book` **belongs to** a `User`, **has many** `Review`s
- `Review` **belongs to** both a `User` and a `Book`
- `User` **has many** `:reviewed_books, through: :reviews` (a `has_many :through`)

---

## Phase 0 — Project Setup

### ☑ Task 0.1 — Enable bcrypt & install gems
- Uncomment `gem "bcrypt", "~> 3.1.7"` in the `Gemfile`.
- Run `bundle install`.
- Verify the app boots: `bin/rails server` → visit `http://localhost:3000`.

> **Concepts:** Bundler, the `Gemfile` & `Gemfile.lock`, gem dependencies, `bin/rails` binstubs, the Rails server (Puma).

---

## Phase 1 — Data Layer (Models, Migrations, Associations)

Build all three database tables and their relationships before touching controllers or views. Get this right and the rest of the app rests on a solid foundation.

### ☑ Task 1.1 — Generate the User model
- `bin/rails generate model User name:string email:string password_digest:string`
- Inspect the generated migration in `db/migrate/`.
- Add a **unique index** on `email` in the migration (`add_index :users, :email, unique: true`).
- `bin/rails db:migrate`.

> **Concepts:** Rails generators, migrations, the `schema.rb` file, database columns & types, database indexes, `password_digest` naming convention (required by `has_secure_password`).

### ☑ Task 1.2 — Generate the Book model
- `bin/rails generate model Book title:string author:string description:text status:integer user:references`
- Note that `user:references` adds a `user_id` column **and** a foreign key.
- Confirm `foreign_key: true` is present in the migration; migrate.

> **Concepts:** `references` / `belongs_to` column generation, `foreign_key: true`, `:text` vs `:string`, integer-backed enums (status is an integer).

### ☑ Task 1.3 — Generate the Review model
- `bin/rails generate model Review content:text rating:integer user:references book:references`
- Migrate.

> **Concepts:** Multiple foreign keys on one table, join-style models (a Review links a User and a Book).

### ☑ Task 1.4 — Wire up associations
- `User`: `has_many :books, dependent: :destroy`, `has_many :reviews, dependent: :destroy`, and `has_many :reviewed_books, through: :reviews, source: :book`.
- `Book`: `belongs_to :user`, `has_many :reviews, dependent: :destroy`.
- `Review`: `belongs_to :user`, `belongs_to :book`.
- Test in `bin/rails console`: create a user, a book, a review; walk the associations (`user.books`, `book.reviews`, `user.reviewed_books`).

> **Concepts:** `has_many` / `belongs_to`, `has_many :through`, the `source:` option, `dependent: :destroy` (cascading deletes), the Rails console, Active Record objects in memory vs persisted.

---

## Phase 2 — Validations, Enums, Callbacks

Now add the rules and behavior that live on the models.

### ☑ Task 2.1 — Validations
- `Book`: `validates :title, presence: true`.
- `Review`: `validates :rating, inclusion: { in: 1..5 }` (or `numericality:` with bounds).
- `User`: `validates :email, presence: true, uniqueness: true`.
- Test invalid records in the console; inspect `record.errors.full_messages`.

> **Concepts:** Active Record validations, `presence`, `uniqueness`, `inclusion`, Ruby **ranges** (`1..5`), the `errors` object, `valid?` / `save` return values.

### ☑ Task 2.2 — Status enum on Book
- Add `enum :status, { want_to_read: 0, reading: 1, finished: 2 }`.
- In the console, try the generated helpers: `book.reading!`, `book.finished?`, `Book.want_to_read`.

> **Concepts:** Active Record **enums**, Ruby **hashes** (the `{ key: value }` mapping), bang methods (`reading!`), predicate methods (`finished?`), enum scopes.

### ☑ Task 2.3 — Callback to downcase email
- Add `before_save { self.email = email.downcase }` (or a named method) on `User`.
- Save a user with a mixed-case email; confirm it persists lowercased.

> **Concepts:** Active Record **callbacks** (`before_save`), the model lifecycle, `self` in instance methods, Ruby string methods (`downcase`), blocks vs named callback methods.

---

## Phase 3 — Authentication, Sessions & Filters

With models in place, add login. This unblocks everything user-scoped.

### ☑ Task 3.1 — Secure passwords
- Add `has_secure_password` to `User` (relies on bcrypt from Task 0.1).
- In the console, create a user with `password` / `password_confirmation`; test `user.authenticate("...")`.

> **Concepts:** `has_secure_password`, password hashing (bcrypt), virtual attributes (`password` isn't a real column — `password_digest` is), `authenticate`.

### ☑ Task 3.2 — Users controller & signup
- Routes: `resources :users, only: [:new, :create]` (or a `signup` route).
- `UsersController#new` / `#create` with **strong params** (`params.require(:user).permit(...)`).
- A signup form view.

> **Concepts:** RESTful routes, `resources`, strong parameters, `render` vs `redirect_to`, form views.

### ☑ Task 3.3 — Sessions controller (login/logout)
- Routes: `get "/login"`, `post "/login"`, `delete "/logout"` mapped to `SessionsController`.
- `#new` (login form), `#create` (find user by email, `authenticate`, set `session[:user_id]`), `#destroy` (reset session).

> **Concepts:** Sessions, the `session` hash, cookies, looking up records (`User.find_by`), the difference between authentication (who you are) and the session (staying logged in).

### ☑ Task 3.4 — current_user, logged_in? & require_login
- In `ApplicationController`: `current_user` (memoized `@current_user ||= User.find_by(id: session[:user_id])`) and `logged_in?`, both exposed via `helper_method`.
- Add `before_action :require_login`.
- `skip_before_action :require_login` on signup and login actions.

> **Concepts:** `before_action` filters, `skip_before_action`, `helper_method` (exposing controller methods to views), **memoization** (`||=`), guard clauses / redirects.

---

## Phase 4 — Books CRUD (REST, Controllers, Views)

The heart of the app: full Create/Read/Update/Delete for books, scoped to the logged-in user.

### ☑ Task 4.1 — Books routes & the 7 REST actions
- `resources :books` and set a `root` route (e.g. `root "books#index"`).
- `BooksController` with all seven actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.
- Scope books to `current_user` (e.g. `current_user.books`).
- Strong params via a private `book_params` method.
- On success: `redirect_to`. On failure: `render :new, status: :unprocessable_entity`.

> **Concepts:** REST & the 7 standard actions, `resources` routing, route helpers (`book_path`, `books_path`), strong params, HTTP status codes (`:unprocessable_entity` = 422), `redirect_to` vs `render`, the controller-action-view flow.

### ☑ Task 4.2 — Layout, views & partials
- Confirm `app/views/layouts/application.html.erb` uses `<%= yield %>`.
- `index` renders a collection: `render @books` (uses `_book.html.erb` partial automatically).
- Shared `_form.html.erb` used by both `new` and `edit`.
- `show`, `new`, `edit` views.

> **Concepts:** Layouts & `yield`, **partials**, collection rendering (`render @books`), the partial naming convention (`_book.html.erb` ↔ `render @books`), ERB syntax (`<%= %>` vs `<% %>`), local variables in partials.

### ☑ Task 4.3 — The book form
- `_form.html.erb` using `form_with model: @book`.
- A status dropdown: `f.select :status, Book.statuses.keys`.
- A delete link with `data: { turbo_method: :delete }` and a confirm.

> **Concepts:** `form_with`, form builders (`f.text_field`, `f.select`, `f.submit`), populating a select from `Book.statuses`, Turbo-driven links, `data-turbo-method`, CSRF protection (handled automatically).

### ☑ Task 4.4 — Flash messages
- `flash[:notice]` after a successful create (survives the `redirect_to`).
- `flash.now[:alert]` on a failed form (used with `render`, does **not** survive a redirect).
- Render flash messages in the layout.

> **Concepts:** The flash, `flash` vs `flash.now`, why redirect needs `flash` and render needs `flash.now` (request lifecycle), displaying flashes in the layout.

---

## Phase 5 — Reviews

Let users review books. Smaller than Books, reinforces the same patterns with **nested** resources.

### ☑ Task 5.1 — Reviews controller & nested routes
- Nest reviews under books: `resources :books do resources :reviews, only: [:create, :destroy] end`.
- `ReviewsController#create` builds the review from `@book.reviews` and `current_user`.
- Show reviews and a review form on the book's `show` page.

> **Concepts:** Nested routes, building associated records (`@book.reviews.build`), associating with `current_user`, reusing strong params & validations.

---

## Phase 6 — Active Record Queries

Refine the data access now that there's data to query.

### ☐ Task 6.1 — Fix the N+1 with includes
- On the books index, eager-load reviews: `current_user.books.includes(:reviews)`.
- Watch the development log before/after to see query counts drop.

> **Concepts:** The **N+1 query problem**, `includes` (eager loading), reading the Rails SQL log, query counts.

### ☐ Task 6.2 — Add a scope
- Add one scope to `Book`, e.g. `scope :recently_added, -> { order(created_at: :desc) }` (or use the enum-generated `Book.finished`).
- Use it in a controller/view.

> **Concepts:** **Scopes**, Ruby **lambdas** (`-> { }`), chainable query methods, `order`.

### ☐ Task 6.3 — Aggregation: review counts per book
- Compute review counts, e.g. `Book.left_joins(:reviews).group(:id).count` or a `counter`/`group` query.
- Display the count next to each book.

> **Concepts:** SQL **aggregation** in Active Record (`group`, `count`), `joins` vs `left_joins`, grouped hash results.

---

## Phase 7 — Assets & Turbo

Polish the front end and *observe* Hotwire's behavior.

### ☐ Task 7.1 — Custom CSS
- Add one custom CSS file and link it via `stylesheet_link_tag` in the layout.

> **Concepts:** The asset pipeline (**Propshaft** in Rails 8), `stylesheet_link_tag`, where stylesheets live, importmap basics.

### ☐ Task 7.2 — Observe Turbo, then disable it on one link
- Notice forms submit without full page reloads (Turbo Drive).
- Add `data: { turbo: false }` to one link and watch the difference (full reload).

> **Concepts:** **Turbo Drive**, intercepted navigation, `data-turbo="false"`, progressive enhancement, the difference between a Turbo visit and a classic full request.

---

## Phase 8 — JSON API

### ☐ Task 8.1 — books.json + custom as_json
- Make `BooksController#index` respond to JSON (`respond_to` or rely on format) so `/books.json` returns all books.
- Override `as_json` on `Book` to **hide one field** (e.g. `user_id`).

> **Concepts:** `respond_to` / format negotiation, the `.json` URL format, serialization, overriding `as_json`, controlling the JSON shape (`only:` / `except:`).

---

## Stretch Goals (only after the core works)

- ☐ **Polymorphic comments** — comment on both Books and Reviews. *(Concepts: polymorphic associations, `belongs_to :commentable, polymorphic: true`.)*
- ☐ **Self-join follows** — users follow other users. *(Concepts: self-referential associations, join models, `has_many :through` on the same table.)*
- ☐ **External API** — pull book covers from the Open Library API. *(Concepts: HTTP clients (`Net::HTTP` / Faraday), parsing JSON, background jobs / caching.)*
- ☐ **Nested forms** — `accepts_nested_attributes_for`. *(Concepts: nested attributes, `fields_for`, building children from form params.)*

---

## Suggested Working Rhythm

1. Read the task's **Concepts** line and skim the relevant [Rails Guide](https://guides.rubyonrails.org/) section.
2. Implement the task.
3. Verify in `bin/rails console` (for models) or the browser (for controllers/views).
4. Commit with a small, descriptive message.
5. Check the box and move to the next task.
