import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { PaginatedResponse, ReminderResponse } from '../types.js';

export const reminderTools: Tool[] = [
  {
    name: 'reminders_list',
    description:
      'Lists all reminders for the authenticated user. Returns id, title, status (OPEN/DONE), remindAt, flag, subflag. Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of reminders to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'reminders_create',
    description:
      'Creates a new reminder. The remindAt field is required and must be a valid RFC3339 datetime.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Reminder title' },
        remindAt: { type: 'string', description: 'When to remind, in RFC3339 format with timezone, e.g. 2026-04-15T09:00:00-03:00 (required)' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title', 'remindAt'],
    },
  },
  {
    name: 'reminders_update',
    description: 'Updates an existing reminder. Only provided fields are changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Reminder UUID' },
        title: { type: 'string', description: 'New title' },
        status: { type: 'string', enum: ['OPEN', 'DONE'], description: 'New status' },
        remindAt: { type: 'string', description: 'New remind datetime (RFC3339 with timezone)' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'reminders_delete',
    description: 'Permanently deletes a reminder. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Reminder UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleRemindersTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'reminders_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ReminderResponse>>(
        'GET',
        `/v1/reminders${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_create': {
      const result = await apiRequest<ReminderResponse>('POST', '/v1/reminders', {
        title: args.title,
        remindAt: args.remindAt,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.status !== undefined) body.status = args.status;
      if (args.remindAt !== undefined) body.remindAt = args.remindAt;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<ReminderResponse>(
        'PATCH',
        `/v1/reminders/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_delete': {
      await apiRequest<void>('DELETE', `/v1/reminders/${args.id}`);
      return JSON.stringify({ message: 'Reminder deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown reminders tool: ${name}`);
  }
}
