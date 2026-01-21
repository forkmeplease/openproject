import { BlockNoteSchema } from "@blocknote/core";
import { ServerBlockNoteEditor } from "@blocknote/server-util";
import type { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload, onTokenSyncPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import { openProjectWorkPackageStaticBlockSpec } from "op-blocknote-extensions";
import * as Y from "yjs";
import { decryptToken } from "../services/decryptTokenService";
import type { ApiResponseDocument } from "../types";

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

interface TokenValidationResult {
  decryptedToken: string;
  readonly: boolean;
}

export class OpenProjectApi implements Extension {
  /**
   * Validate an encrypted token against the OpenProject API
   * Returns the decrypted token and readonly status, or null if validation fails
   */
  private async validateToken(encryptedToken: string, resourceUrl: string): Promise<TokenValidationResult | null> {
    const decryptedToken = decryptToken(encryptedToken);

    const response = await fetch(resourceUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${decryptedToken}`,
      },
    });

    if (!response.ok) {
      return null;
    }

    const jsonData = await response.json() as ApiResponseDocument;
    return {
      decryptedToken,
      readonly: !jsonData._links?.update,
    };
  }

  /**
   * Authenticate the user by validating the token and document access
   */
  async onAuthenticate(data: onAuthenticatePayload) {
    const { token, documentName } = data;
    const resourceUrl = documentName;

    if (!token) {
      throw new Error('Unauthorized: Token missing.');
    }

    const result = await this.validateToken(token, resourceUrl);
    if (!result) {
      throw new Error('Unauthorized: Invalid token or document access denied.');
    }

    data.context.resourceUrl = resourceUrl;
    data.context.token = result.decryptedToken;
    if (result.readonly) {
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
   * Handle token sync from clients (triggered by provider.sendToken())
   */
  async onTokenSync(data: onTokenSyncPayload): Promise<void> {
    const { token, connection } = data;
    if (!token) {
      return;
    }

    const { resourceUrl } = connection.context;
    if (!resourceUrl) {
      return;
    }

    try {
      const result = await this.validateToken(token, resourceUrl);
      if (!result) {
        printLog(`Token sync failed for ${resourceUrl}`);
        return;
      }

      connection.context.token = result.decryptedToken;

      // Update permissions if changed
      const isReadOnly = result.readonly;
      if (isReadOnly !== connection.readOnly) {
        connection.readOnly = isReadOnly;
        connection.context.readonly = isReadOnly;
      }

      printLog(`[Token Synced] Resource: ${resourceUrl} Readonly: ${result.readonly}`);
    } catch (error) {
      printLog(`Token sync error: ${error}`);
    }
  }
}

