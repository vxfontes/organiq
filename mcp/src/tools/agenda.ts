import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { EventResponse, ReminderResponse, TaskResponse } from '../types.js';

interface AgendaResponse {
  events: EventResponse[];
  tasks: TaskResponse[];
  reminders: ReminderResponse[];
}

export const agendaTools: Tool[] = [
  {
    name: 'agenda_get',
    description:
      "Returns a unified view of the user's agenda: events, tasks, and reminders in a single call. Use this when the user asks \"what do I have coming up\", \"show my schedule\", or wants an overview of their day/week.",
    inputSchema: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
];

export async function handleAgendaTool(
  name: string,
  _args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'agenda_get': {
      const result = await apiRequest<AgendaResponse>('GET', '/v1/agenda');
      return JSON.stringify(result, null, 2);
    }

    default:
      throw new Error(`Unknown agenda tool: ${name}`);
  }
}
