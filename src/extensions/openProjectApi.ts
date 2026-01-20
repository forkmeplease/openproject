import { BlockNoteSchema } from "@blocknote/core";
import { ServerBlockNoteEditor } from "@blocknote/server-util";
import type { onAuthenticatePayload, onLoadDocumentPayload, onStatelessPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import { openProjectWorkPackageStaticBlockSpec } from "op-blocknote-extensions";
import * as Y from "yjs";
import { decryptToken } from "../services/decryptTokenService";
import type { ApiResponseDocument } from "../types";

const TOKEN_REFRESH_PREFIX = "REFRESH:";

export const editorSchema = BlockNoteSchema.create().extend({
  blockSpecs: {
    "openProjectWorkPackage": openProjectWorkPackageStaticBlockSpec(),
  },
});

function printLog(message:string) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

export function createEditor() {
  return ServerBlockNoteEditor.create({ schema: editorSchema });
}

export class OpenProjectApi implements Extension {
  /**
    * Authenticate the user by validating the token and document access
    */
  async onAuthenticate(data: onAuthenticatePayload) {
    const { token, documentName } = data;
    const resourceUrl = documentName;

    if (!token) {
      throw new Error('Unauthorized: Token missing.');
    }
    const decryptedToken = decryptToken(token);

    const response = await fetch(resourceUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${decryptedToken}`,
      },
    });

    if (!response.ok) {
      throw new Error('Unauthorized: Invalid token or document access denied.');
    }
    const jsonData = await response.json() as ApiResponseDocument;

    data.context.resourceUrl = resourceUrl;
    data.context.token = decryptedToken;
    if (!jsonData._links?.update) {
      // https://tiptap.dev/docs/hocuspocus/guides/auth#read-only-mode
      data.connectionConfig.readOnly = true;
      data.context.readonly = true;
    }
  }

  /**
    * Retrieve data from the API. This should return the YDoc data
    */
  async onLoadDocument(data: onLoadDocumentPayload) {
    const { resourceUrl } = data.context;

    printLog(`GET ${resourceUrl}`);

    const response = await fetch(resourceUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${data.context.token}`,
      },
    });

    if (!response.ok) {
      console.warn(`Error fetching document: ${response.statusText}`);
      return;
    }

    const jsonData = await response.json() as ApiResponseDocument;
    if (jsonData.contentBinary) {
      const update = new Uint8Array(Buffer.from(jsonData.contentBinary, 'base64'));
      Y.applyUpdate(data.document, update);
    }

    return data.document;
  }

  /**
    * Store data to the API. The data is a YDoc update
    */
  async onStoreDocument(data: onStoreDocumentPayload): Promise<void> {
    const { resourceUrl, readonly } = data.context;

    if (!resourceUrl) {
      console.warn("Missing parameters in context. Skipping store.");
      return;
    }
    if (readonly) {
      console.warn("Readonly user cannot make requests to store the document");
      return;
    }

    printLog(`PATCH ${resourceUrl}`);

    const base64Data = Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64");

    // Create a copy of the document to avoid side effects
    const editor = createEditor();
    const tempYdoc = new Y.Doc();
    Y.applyUpdate(tempYdoc, Y.encodeStateAsUpdate(data.document));
    const tempFragment = tempYdoc.getXmlFragment("document-store");
    const editorData = editor.yXmlFragmentToBlocks(tempFragment);
    // @ts-expect-error BlockNote types are complicated
    const markdownData = await editor.blocksToMarkdownLossy(editorData);

    const response = await fetch(resourceUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${data.context.token}`,
      },
      body: JSON.stringify({
        content_binary: base64Data,
        description: markdownData,
      }),
    });

    if (!response.ok) {
      console.warn(`Error storing document: ${response.statusText}`);
      return;
    }

    data.document.connections.forEach(({ connection }) => connection.sendStateless("storeEvent"));
  }

  /**
    * Handle stateless messages from clients
    */
  async onStateless(data: onStatelessPayload): Promise<void> {
    const { payload, connection } = data;

    if (payload.startsWith(TOKEN_REFRESH_PREFIX)) {
      const encryptedToken = payload.slice(TOKEN_REFRESH_PREFIX.length);
      await this.handleTokenRefresh(encryptedToken, connection);
    }
  }

  /**
    * Process a token refresh request from the client
    */
  private async handleTokenRefresh(encryptedToken: string, connection: onStatelessPayload["connection"]): Promise<void> {
    if (!encryptedToken) {
      return;
    }

    const { resourceUrl } = connection.context;
    if (!resourceUrl) {
      return;
    }

    try {
      const decryptedToken = decryptToken(encryptedToken);

      const response = await fetch(resourceUrl, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${decryptedToken}`,
        },
      });

      if (!response.ok) {
        printLog(`Token refresh failed: ${response.statusText}`);
        return;
      }

      const jsonData = await response.json() as ApiResponseDocument;

      connection.context.token = decryptedToken;

      const wasReadonly = connection.context.readonly;
      const isReadonly = !jsonData._links?.update;

      if (wasReadonly !== isReadonly) {
        connection.context.readonly = isReadonly;
        connection.readOnly = isReadonly;
        printLog(`Readonly status changed: ${isReadonly}`);
      }
    } catch (error) {
      printLog(`Token refresh error: ${error}`);
    }
  }
}

