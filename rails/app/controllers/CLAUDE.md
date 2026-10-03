# Controller creation rules

## Area namespacing

- Resource controllers live in an area namespace: plural module (`Admins::`,
  `Members::`, …) mapped to its URL prefix (`/admin`, `/app`, …).
  <!-- TODO: List this project's areas, their modules and URL prefixes. -->
- Each namespaced controller inherits the area's `BaseController`, which
  enforces the area's access gate — never inherit `ApplicationController`
  directly inside an area.

## Authorization (Pundit, namespaced policies)

- Every action calls `authorize` with the area-namespaced policy:
  - member actions: `authorize [ :admins, @record ]`
  - collection actions: `authorize %i[ admins record ]`
- Record lookup always goes through `policy_scope`, inside a `set_*`
  before_action: `policy_scope([ :admins, Record ]).find(params[:id])`.
  Never `Model.find` directly.

## Responses

- Success: redirect with a flash from i18n —
  `notice: t("admins.records.create.success")`. Flash text is never
  hardcoded.
- Validation failure: re-render the form template with
  `status: :unprocessable_entity`.
- Guarded destroy failure: redirect back to the record with
  `alert: @record.errors.full_messages.to_sentence`.

## Strong parameters

- One private `*_params` method per form shape (e.g. `record_params`,
  `update_status_params`), using `params.require(...).permit(...)`.

<!-- TODO: Name the controller that serves as the reference implementation of
all of the above. -->
