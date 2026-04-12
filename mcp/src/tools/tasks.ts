import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { PaginatedResponse, TaskResponse } from '../types.js';

export const taskTools: Tool[] = [
  {
    name: 'tasks_list',
    description:
      'Lists all tasks for the authenticated user. Returns id, title, description, status (OPEN/DONE), dueAt, flag, subflag, and sourceInboxItem. Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of tasks to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'tasks_create',
    description:
      'Creates a new task directly (without going through the inbox). Use this when the user explicitly says they want to create a task.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Task title' },
        description: { type: 'string', description: 'Optional task description' },
        dueAt: { type: 'string', description: 'Optional due date in RFC3339 format' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title'],
    },
  },
  {
    name: 'tasks_update',
    description:
      'Updates an existing task. Only provided fields are changed. Use status DONE to mark as complete, OPEN to reopen.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Task UUID' },
        title: { type: 'string', description: 'New title' },
        description: { type: 'string', description: 'New description' },
        status: { type: 'string', enum: ['OPEN', 'DONE'], description: 'New status' },
        dueAt: { type: 'string', description: 'New due date (RFC3339) or null to clear' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'tasks_delete',
    description: 'Permanently deletes a task. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Task UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleTasksTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'tasks_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<TaskResponse>>(
        'GET',
        `/v1/tasks${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_create': {
      const result = await apiRequest<TaskResponse>('POST', '/v1/tasks', {
        title: args.title,
        description: args.description ?? null,
        dueAt: args.dueAt ?? null,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.description !== undefined) body.description = args.description;
      if (args.status !== undefined) body.status = args.status;
      if (args.dueAt !== undefined) body.dueAt = args.dueAt;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<TaskResponse>('PATCH', `/v1/tasks/${args.id}`, body);
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_delete': {
      await apiRequest<void>('DELETE', `/v1/tasks/${args.id}`);
      return JSON.stringify({ message: 'Task deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown tasks tool: ${name}`);
  }
}
