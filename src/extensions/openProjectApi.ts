import type { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import * as Y from "yjs";
import type { ApiResponseDocument } from "../types";
import { ServerBlockNoteEditor } from "@blocknote/server-util";
import { BlockNoteSchema } from "@blocknote/core";
import { openProjectWorkPackageStaticBlockSpec } from "op-blocknote-extensions";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    "openProjectWorkPackage": openProjectWorkPackageStaticBlockSpec(),
  },
});

export class OpenProjectApi implements Extension {
  /**
    * Authenticate the user by validating the token and document access
    */
  async onAuthenticate(data: onAuthenticatePayload) {
    const { token, documentName, requestParameters } = data;
    const documentId = requestParameters.get("document_id");
    const opBasePath = requestParameters.get("openproject_base_path");

    if (!token) {
      throw new Error('Unauthorized: Token missing.');
    }

    if (!opBasePath) {
      throw new Error('Unauthorized: Base URL missing.');
    }

    // Validate opBasePath against allowed domains
    const allowedDomains = process.env.ALLOWED_DOMAINS?.split(',') || [];
    if (allowedDomains.length <= 0) {
      throw new Error('Unauthorized: No allowed domains configured.');
    }
    
    try {
      const url = new URL(opBasePath);
      const isAllowed = allowedDomains.some(domain =>
        url.hostname === domain.trim() || url.hostname.endsWith('.' + domain.trim())
      );

      if (!isAllowed) {
        throw new Error('Unauthorized: Invalid base URL domain.');
      }
    } catch (error) {
      if (error instanceof TypeError) {
        throw new Error('Unauthorized: Invalid base URL format.');
      }
      throw error;
    }

    const targetUrl = `${opBasePath}/api/v3/documents/${documentId}`;
    const response = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error('Unauthorized: Invalid token.');
    }
    const jsonData = await response.json() as ApiResponseDocument;

    if (!jsonData.title || jsonData.title !== documentName) {
      throw new Error('Unauthorized: Document access denied.');
    }

    data.documentName = jsonData.title;
    data.context.documentId = documentId;
    data.context.token = token;
    data.context.opBasePath = opBasePath;
  }

  /**
    * Retrieve data from the API. This should return the YDoc data
    */
  async onLoadDocument(data: onLoadDocumentPayload) {
    const { documentId, opBasePath } = data.context;

    const targetUrl = `${opBasePath}/api/v3/documents/${documentId}`;
    console.log(`GET ${targetUrl}`);

    const response = await fetch(targetUrl, {
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
  }

  /**
    * Store data to the API. The data is a YDoc update
    */
  async onStoreDocument(data: onStoreDocumentPayload): Promise<void> {
    const { documentId, opBasePath } = data.context;

    if (!documentId || !opBasePath) {
      console.warn("Missing documentId or opBasePath in context. Skipping store.");
      return;
    }

    const targetUrl = `${opBasePath}/api/v3/documents/${documentId}`;
    console.log(`PATCH ${targetUrl}`);

    const base64Data = Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64");

    // Create a copy of the document to avoid side effects
    const editor = ServerBlockNoteEditor.create({ schema });
    const tempYdoc = new Y.Doc();
    Y.applyUpdate(tempYdoc, Y.encodeStateAsUpdate(data.document));
    const tempFragment = tempYdoc.getXmlFragment("document-store");
    const editorData = editor.yXmlFragmentToBlocks(tempFragment);
    // @ts-expect-error BlockNote types are complicated
    const markdownData = await editor.blocksToMarkdownLossy(editorData);

    const response = await fetch(targetUrl, {
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
    }
  }
}

