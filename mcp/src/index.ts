import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { initAuth } from './client.js';
import { agendaTools, handleAgendaTool } from './tools/agenda.js';
import { authTools, handleAuthTool } from './tools/auth.js';
import { eventTools, handleEventsTool } from './tools/events.js';
import { inboxTools, handleInboxTool } from './tools/inbox.js';
import { reminderTools, handleRemindersTool } from './tools/reminders.js';
import { shoppingTools, handleShoppingTool } from './tools/shopping.js';
import { taskTools, handleTasksTool } from './tools/tasks.js';

await initAuth();

const server = new Server(
  { name: 'organiq', version: '0.1.0' },
  { capabilities: { tools: {} } },
);

const allTools = [
  ...authTools,
  ...inboxTools,
  ...taskTools,
  ...reminderTools,
  ...eventTools,
  ...shoppingTools,
  ...agendaTools,
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: allTools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const safeArgs = (args ?? {}) as Record<string, unknown>;

  try {
    let result: string;

    if (name.startsWith('auth_')) {
      result = await handleAuthTool(name, safeArgs);
    } else if (name.startsWith('inbox_')) {
      result = await handleInboxTool(name, safeArgs);
    } else if (name.startsWith('tasks_')) {
      result = await handleTasksTool(name, safeArgs);
    } else if (name.startsWith('reminders_')) {
      result = await handleRemindersTool(name, safeArgs);
    } else if (name.startsWith('events_')) {
      result = await handleEventsTool(name, safeArgs);
    } else if (name.startsWith('shopping_')) {
      result = await handleShoppingTool(name, safeArgs);
    } else if (name === 'agenda_get') {
      result = await handleAgendaTool(name, safeArgs);
    } else {
      throw new Error(`Unknown tool: ${name}`);
    }

    return { content: [{ type: 'text', text: result }] };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      content: [{ type: 'text', text: `Error: ${message}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
