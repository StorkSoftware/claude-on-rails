# Models

The structural map of the domain, and the rules for writing the models
themselves. The ubiquitous language is in [CONTEXT.md](../../CONTEXT.md), the
tables underneath are in [db/README.md](../../db/README.md), and the decisions
behind both are in [docs/adr/](../../docs/adr/).

## Structural map

<!-- TODO: Group the models into the same clusters as the schema in
db/README.md, so the two documents can be read side by side. For each model,
one or two lines: what it is, its key associations, and any rule that is not
obvious from the code. -->

A model with **no table** is a query object, and is marked as such where it
appears.

## Ordering

The code in model files should be ordered as follows:

1. Associations (`accepts_nested_attributes_for` sits immediately after the
   association it configures)
2. Validations
3. Callbacks
4. Ruby definitions: frozen constants, `enum`, and framework macros
   (`rolify`, `has_secure_password`, `normalizes`, …)
5. Scopes
6. Delegations
7. Class methods
8. Instance methods
9. Private methods

Exception: a definition may move above its slot when something earlier needs
it at class-load time — e.g. `User::ROLES` is defined first because a
validation references it.

## Deletion semantics

- Removals never cascade by default. Parent-side associations use
  `dependent: :restrict_with_error`, and models with dependents add a
  prepended `before_destroy` guard listing them (a `prevent_if_dependent`
  callback reading a `DEPENDENT_ASSOCIATIONS` constant).
- Cascading a destroy is a deliberate per-case decision, made explicitly —
  never assumed. No foreign key carries `ON DELETE` but those named below; the
  guard is otherwise always here.
- The exceptions: `user → sessions` destroys.
  <!-- TODO: List every other association or foreign key that cascades or
  nullifies, and why. -->
- This drives the UI split in [app/views/CLAUDE.md](../views/CLAUDE.md):
  guarded resources route deletion through their show page so a refused
  destroy can render its errors.
