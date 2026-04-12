import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type {
  ConfirmResponse,
  InboxItemResponse,
  PaginatedResponse,
} from '../types.js';

export const inboxTools: Tool[] = [
  {
    name: 'inbox_list',
    description:
      'Lists items in the Organiq inbox. Filter by status (NEW, PROCESSING, SUGGESTED, NEEDS_REVIEW, CONFIRMED, DISMISSED) or source (manual, share, ocr). Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: ['NEW', 'PROCESSING', 'SUGGESTED', 'NEEDS_REVIEW', 'CONFIRMED', 'DISMISSED'],
          description: 'Filter by item status',
        },
        source: {
          type: 'string',
          enum: ['manual', 'share', 'ocr'],
          description: 'Filter by item source',
        },
        limit: { type: 'number', description: 'Number of items to return' },
        cursor: { type: 'string', description: 'Pagination cursor from previous response' },
      },
      required: [],
    },
  },
  {
    name: 'inbox_get',
    description:
      'Gets a single inbox item by ID, including the AI suggestion if one exists (type, title, confidence, payload).',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'inbox_create',
    description:
      'Creates a new raw item in the inbox. The item starts with status NEW. Use inbox_reprocess to trigger AI classification afterwards.',
    inputSchema: {
      type: 'object',
      properties: {
        rawText: { type: 'string', description: 'The raw text to add to the inbox' },
        source: {
          type: 'string',
          enum: ['manual', 'share', 'ocr'],
          description: 'Source of the item (default: manual)',
        },
      },
      required: ['rawText'],
    },
  },
  {
    name: 'inbox_reprocess',
    description:
      'Sends an inbox item to the AI for (re)classification. Updates the item status to SUGGESTED or NEEDS_REVIEW and stores the AI suggestion. Requires the AI client to be configured on the server.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'inbox_confirm',
    description:
      'Confirms an inbox item, creating the final entity. The item status changes to CONFIRMED. ' +
      'Supported types: task, reminder, event, shopping. ' +
      'Payload per type — task: { dueAt? (RFC3339 with timezone) }, reminder: { at (required RFC3339 with timezone) }, event: { start (RFC3339 with timezone), end?, allDay }, shopping: { items: [{ title, quantity? }] }',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
        type: {
          type: 'string',
          enum: ['task', 'reminder', 'event', 'shopping'],
          description: 'Type of entity to create',
        },
        title: { type: 'string', description: 'Title of the final entity' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
        payload: {
          type: 'object',
          description:
            'Type-specific payload. task: {dueAt?}. reminder: {at}. event: {start, end?, allDay}. shopping: {items:[{title,quantity?}]}',
        },
      },
      required: ['id', 'type', 'title', 'payload'],
    },
  },
  {
    name: 'inbox_dismiss',
    description: 'Dismisses an inbox item, marking it as DISMISSED. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleInboxTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'inbox_list': {
      const params = new URLSearchParams();
      if (args.status) params.set('status', args.status as string);
      if (args.source) params.set('source', args.source as string);
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<InboxItemResponse>>(
        'GET',
        `/v1/inbox-items${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_get': {
      const result = await apiRequest<InboxItemResponse>(
        'GET',
        `/v1/inbox-items/${args.id}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_create': {
      const result = await apiRequest<InboxItemResponse>('POST', '/v1/inbox-items', {
        rawText: args.rawText,
        source: args.source ?? 'manual',
      });
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_reprocess': {
      const result = await apiRequest<InboxItemResponse>(
        'POST',
        `/v1/inbox-items/${args.id}/reprocess`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_confirm': {
      const result = await apiRequest<ConfirmResponse>(
        'POST',
        `/v1/inbox-items/${args.id}/confirm`,
        {
          type: args.type,
          title: args.title,
          flagId: args.flagId ?? null,
          subflagId: args.subflagId ?? null,
          payload: args.payload,
        },
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_dismiss': {
      await apiRequest<void>('POST', `/v1/inbox-items/${args.id}/dismiss`);
      return JSON.stringify({ message: 'Item dismissed successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown inbox tool: ${name}`);
  }
}
