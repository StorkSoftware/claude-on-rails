# Database rules

## README.md is part of the schema change

[README.md](README.md) documents the schema: a Mermaid ER diagram plus a column
and constraint reference. It is hand-written, so nothing regenerates it — **any
change that lands in [schema.rb](schema.rb) must land in README.md in the same
commit.**

That means every migration, without exception: new tables, dropped tables, added
or removed columns, renames, changed nullability or defaults, new or dropped
indexes and unique indexes, check constraints, foreign keys, and PG enum
changes. A column that only tightens a default still moves a row in the
reference table.

What to touch, per change:

| Change | Update |
| --- | --- |
| New or dropped table | the cluster index, the `erDiagram`, its cluster's column table, and the deletion notes if it has dependents |
| New or changed foreign key | the `erDiagram` relationship, with the right cardinality; the Deletion section if it carries `ON DELETE` |
| Column added, removed, renamed, or retyped | the table's `Columns` cell |
| Unique index, check constraint, partial index | the table's `Rules in the database` cell — this column is the point of the document |
| Anything at all | the **schema version stamp** near the top, to the new `define(version:)` value |

The version stamp is what makes staleness visible. If it doesn't match
schema.rb, a reader knows not to trust the rest.

## How README.md is structured

- The schema is drawn in **clusters** rather than one sheet, listed in the
  cluster index at the top. A hub table may appear in more than one cluster's
  diagram; it is described in the column table of one cluster only.
- Each cluster gets a sentence or two on what it models, a Mermaid
  `erDiagram`, and a table of **Table | Columns | Rules in the database**.
- A new table joins the cluster whose tables it joins most; start a new
  cluster only when it fits none of them.
- Framework-owned tables (rolify, Action Text, Active Storage, Solid adapters)
  go in the Framework tables list, not in a diagram.

## What belongs in README.md

Facts the schema states, and the reasoning that isn't obvious from the column
names. Rules enforced by PostgreSQL — unique and partial unique indexes, check
constraints, PG enums, `NOT NULL`, column defaults, `ON DELETE` clauses — are
the reason the file exists; spell them out rather than leaving them to be read
off `schema.rb`. Where a rule lives in Ruby instead, mark it **in Ruby**,
because that distinction is invisible in a diagram.

Below each cluster's table, explain only what the columns cannot say:

- a denormalized column, and the index or constraint it exists to support;
- a nullable column or a missing default, when absence carries meaning;
- a value that is derived and deliberately not stored;
- a deliberate cascade or nullify, and why.

The **structural map** does not belong here. The models standing on these
tables, the query objects that are deliberately not tables, and the shape of
models not yet built all live in
[app/models/CLAUDE.md](../app/models/CLAUDE.md): a rule PostgreSQL enforces is
documented here, the model that reads it is documented there. This folder is
schema and migrations only.

Don't restate what the ADRs or PRDs already argue — cite them. Don't list `id`,
`created_at`, or `updated_at`.

## Migrations

- Always generate them: `bin/rails generate migration …`, never a hand-written
  file. Same for the models and resources that go with them.
- Deletion never cascades by default; see [app/models/CLAUDE.md](../app/models/CLAUDE.md).
  A cascading destroy is a per-case decision, made explicitly.
- Run `bin/rails db:migrate` so `schema.rb` regenerates, then update README.md
  from the diff. Both files are part of the commit.

## Database Safety

NEVER run `db:drop`, `db:reset`, `db:schema:load`, or any destructive DB task
against development or production. To load seed data, use additive loaders only
(e.g. call the seed class directly). If a task would drop data, STOP and ask
first.
