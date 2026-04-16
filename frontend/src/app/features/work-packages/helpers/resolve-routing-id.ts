import { States } from 'core-app/core/states/states.service';

/**
 * Resolve a numeric work package ID to its semantic routing ID (e.g. "PROJ-42").
 * Falls back to the input ID if the WP is not in cache or has no displayId —
 * this is a best-effort lookup, not a guarantee. The URL just shows the
 * numeric ID temporarily until the WP is cached.
 *
 * Used in navigation handlers where only the numeric PK is available from
 * data-work-package-id attributes, but the URL should show the semantic form.
 */
export function resolveRoutingId(states:States, workPackageId:string):string {
  const wp = states.workPackages.get(workPackageId)?.value;
  return wp?.displayId ?? workPackageId;
}
