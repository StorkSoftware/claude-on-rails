# Locale rules

## Structure

- Locales: `en.yml` <!-- TODO: list any other locales, e.g. `de.yml` -->.
  All locales are always updated together — never add a key to one without
  the others.
- View copy keys mirror the view path so Rails lazy lookup works:
  `t(".heading")` in `app/views/admins/records/index.html.erb` resolves
  to `admins.records.index.heading`.
- Generic actions live in a shared top-level `actions` scope (`actions.edit`,
  `actions.delete`, `actions.new`, `actions.back_to` (takes an entity
  argument), `actions.cancel`, `actions.save`, …). Reuse these — don't mint
  per-resource keys for generic verbs. Create the scope if it doesn't exist
  yet; older per-resource action keys get migrated as their views are touched.
- Model attribute names go under `activerecord.attributes.<model>`;
  validation messages under `activerecord.errors`.
- Validation messages start **lowercase** — Rails composes them as
  "Attribute message" in `full_messages`, so a leading capital reads wrong
  there. A view rendering `full_messages` needs nothing further: the attribute
  name in front already carries the sentence capital. A view rendering a bare
  `error.message` — the `:base` banners, which Rails leaves unprefixed —
  supplies it with `upcase_first`, never `capitalize`. `capitalize` also
  downcases everything after the first character, flattening the names these
  messages interpolate ("Project Alpha" becomes "project alpha"). A message
  only ever added to `:base` may start capitalised: nothing composes it.

## Copy voice

Applies to **every** locale.

- Sentence case everywhere — buttons, headings, menu items, table headers.
  Never Title Case.
- No emoji. Minimal punctuation; no exclamation marks in chrome (an occasional
  friendly one in an empty state is the ceiling).
- Buttons: 1–3 words, verb-first ("Save changes", "Add member"). Labels are
  nouns ("Name", "Start date"). Helper text, hints, and empty states are one
  calm sentence ("No projects yet. Create your first one to get started.").
- Warm, plain, direct — lead with the helpful thing, skip hype. Address the
  user as "you"; speak about people by name or role.
- Use "·" as a compact separator in meta lines ("Updated 3 days ago · 12
  items") and "—" for asides.
