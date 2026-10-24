# View creation rules

## Components

- Build every view from **Tailwind Plus** components, fetched through the
  `TailwindPlusServer` MCP server. Look the component up first and adapt the
  closest match (buttons, form layouts, tables, stacked lists, description
  lists, empty states, page headings) rather than writing markup from scratch:
  - `search_components` — find candidates by name or keyword;
    `list_subcategories` shows what exists when a search comes up empty.
  - `get_component` — fetch the HTML of the chosen match, then convert it to
    ERB with Rails helpers (`form_with`, `link_to`, `button_to`, `t()`).
  - Prefer the **Application UI** product for views inside the app; use
    **Marketing** only for public pages.
- Style with plain Tailwind utilities. Every view supports light and dark mode
  (`dark:` variants) and is mobile-first (responsive modifiers).

## Technology constraints

- HTML + CSS + Turbo Frames only.
- Stimulus controllers and any JS live in `app/javascript/` — do not add
  `<script>` tags or inline JS in views.
- No JS frameworks (React, Vue, Alpine, etc.).

## Standard view conventions

Never perform SQL queries inside the views or partials. Always note that a 
model instance or class method is required to wrap a query. Always use 
helper methods to fetch data and pass it to the view. Use memoized 
instance variables to store fetched data. Never use N+1 queries or loop 
inside views. Always use **pundit authorization** to check permissions.

### `index` views

- Include a "New {entity}" link (small primary button, navigates to `new`) in
  the heading row unless creation is not permitted for that resource.
- Row actions depend on how safely the resource can be destroyed. Removals
  never cascade by default (see [app/models/CLAUDE.md](../models/CLAUDE.md)):
  - **Guarded resources** (have dependents, deletion can fail): each row is a
    single link to `show` with a trailing `chevron-right` icon; Edit/Delete
    live on the show page.
  - **Flat, frequently-edited resources with no dependents**: inline `[Edit]`
    (link to `edit`) and `[Destroy]` (`button_to … method: :delete` with
    `data: { turbo_confirm: … }`) per row are fine.
- Always render an empty state when the list is empty: centered, muted
  one-sentence copy, built from the Tailwind Plus empty state component.

### `show` views

- Include a "← Back to {entities}" link at the top that navigates to the
  `index` path.
- For guarded resources the heading row carries the actions: Edit (secondary
  button link) and Delete (`button_to`, danger button,
  `data: { turbo_confirm: … }`).
- Attribute read-outs use the Tailwind Plus description list component.
- Never add forms to show pages. Instead, use edit pages.

### Forms

- Rails `form_with`, laid out with a Tailwind Plus form layout component.
- Base errors render in an alert banner at the top of the form; per-attribute
  errors render as red hint text under the input.
- A bare `error.message` gets its sentence capital from `upcase_first`, never
  `capitalize`; `full_messages` already carries one — see
  [config/locales/CLAUDE.md](../../config/locales/CLAUDE.md).
- Every input has a `<label>`; use the same field markup (label, input, hint,
  error) across all forms rather than hand-rolling variants.

<!-- TODO: Name the views that serve as reference implementations for index,
show and form pages. -->

## Page structure

- Always add a level 1 heading from the Tailwind Plus page heading component,
  inside a `mx-auto max-w-3xl` container (wider only where content demands it).
- Content sits on card-like surfaces: bordered lists and description lists for
  collections, cards for prose, empty states, and form wrappers. Don't put flat
  text straight on the page background.

## Localisation

- Every user-facing string goes through `t()`; add it to every locale listed
  in [config/locales/CLAUDE.md](../../config/locales/CLAUDE.md).
- Use lazy lookup for view-specific copy: `t(".heading")`.
- Generic actions (Edit, Delete, New, Back, Cancel, Save…) come from the
  shared `actions.*` scope — don't mint per-resource keys for them. Older
  views use per-resource action keys; migrate them whenever you touch the view.
- Copy voice rules live in [config/locales/CLAUDE.md](../../config/locales/CLAUDE.md).
