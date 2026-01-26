const OPENPROJECT_DIRECT_HOSTNAME = process.env.OPENPROJECT_DIRECT_HOSTNAME;
if (OPENPROJECT_DIRECT_HOSTNAME) {
  const openProjectDirectUrl = new URL(OPENPROJECT_DIRECT_HOSTNAME);
  if (!openProjectDirectUrl.protocol || !openProjectDirectUrl.hostname) {
    throw new Error(`Invalid OPENPROJECT_DIRECT_HOSTNAME: ${OPENPROJECT_DIRECT_HOSTNAME}`);
  }

  console.log(`using OPENPROJECT_DIRECT_HOSTNAME: ${OPENPROJECT_DIRECT_HOSTNAME}`);
}

/**
 * Replaces the hostname of the given resource URL with the explicit host
 * if a direct hostname is defined
 */
export function replaceWithExplicitHost(resourceUrl:string):string {
  if (!OPENPROJECT_DIRECT_HOSTNAME) {
    return resourceUrl;
  }

  const url = new URL(OPENPROJECT_DIRECT_HOSTNAME);
  url.pathname = new URL(resourceUrl).pathname;
  return url.toString();
}
