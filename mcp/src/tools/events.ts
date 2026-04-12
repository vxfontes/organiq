import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { EventResponse, PaginatedResponse } from '../types.js';

export const eventTools: Tool[] = [
  {
    name: 'events_list',
    description:
      'Lists all calendar events for the authenticated user. Returns id, title, startAt, endAt, allDay, location, flag, subflag. Supports pagination.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of events to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'events_create',
    description:
      'Creates a new calendar event. startAt is required. endAt must be after startAt if provided. Use allDay: true for full-day events.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Event title' },
        startAt: { type: 'string', description: 'Start datetime in RFC3339 format with timezone, e.g. 2026-04-15T14:00:00-03:00 (required)' },
        endAt: { type: 'string', description: 'End datetime in RFC3339 format' },
        allDay: { type: 'boolean', description: 'Whether this is an all-day event' },
        location: { type: 'string', description: 'Optional location string' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title', 'startAt'],
    },
  },
  {
    name: 'events_update',
    description: 'Updates an existing event. Only provided fields are changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Event UUID' },
        title: { type: 'string', description: 'New title' },
        startAt: { type: 'string', description: 'New start datetime (RFC3339)' },
        endAt: { type: 'string', description: 'New end datetime (RFC3339) or null to clear' },
        allDay: { type: 'boolean', description: 'New allDay value' },
        location: { type: 'string', description: 'New location or null to clear' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'events_delete',
    description: 'Permanently deletes a calendar event. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Event UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleEventsTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'events_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<EventResponse>>(
        'GET',
        `/v1/events${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'events_create': {
      const result = await apiRequest<EventResponse>('POST', '/v1/events', {
        title: args.title,
        startAt: args.startAt,
        endAt: args.endAt ?? null,
        allDay: args.allDay ?? false,
        location: args.location ?? null,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'events_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.startAt !== undefined) body.startAt = args.startAt;
      if (args.endAt !== undefined) body.endAt = args.endAt;
      if (args.allDay !== undefined) body.allDay = args.allDay;
      if (args.location !== undefined) body.location = args.location;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<EventResponse>(
        'PATCH',
        `/v1/events/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'events_delete': {
      await apiRequest<void>('DELETE', `/v1/events/${args.id}`);
      return JSON.stringify({ message: 'Event deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown events tool: ${name}`);
  }
}
