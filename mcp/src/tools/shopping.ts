import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type {
  PaginatedResponse,
  ShoppingItemResponse,
  ShoppingListResponse,
} from '../types.js';

export const shoppingTools: Tool[] = [
  {
    name: 'shopping_lists_list',
    description:
      'Lists all shopping lists for the authenticated user. Returns id, title, status (OPEN/DONE/ARCHIVED). Supports pagination.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of lists to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'shopping_lists_create',
    description: 'Creates a new shopping list with the given title.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Shopping list title' },
      },
      required: ['title'],
    },
  },
  {
    name: 'shopping_lists_update',
    description:
      'Updates a shopping list title or status. Status values: OPEN, DONE, ARCHIVED.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping list UUID' },
        title: { type: 'string', description: 'New title' },
        status: {
          type: 'string',
          enum: ['OPEN', 'DONE', 'ARCHIVED'],
          description: 'New status',
        },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_lists_delete',
    description: 'Permanently deletes a shopping list and all its items. Irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping list UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_items_list',
    description: 'Lists all items in a shopping list. Returns id, title, quantity, checked, sortOrder.',
    inputSchema: {
      type: 'object',
      properties: {
        listId: { type: 'string', description: 'Shopping list UUID' },
        limit: { type: 'number', description: 'Number of items to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: ['listId'],
    },
  },
  {
    name: 'shopping_items_create',
    description: 'Adds a new item to a shopping list.',
    inputSchema: {
      type: 'object',
      properties: {
        listId: { type: 'string', description: 'Shopping list UUID' },
        title: { type: 'string', description: 'Item name' },
        quantity: { type: 'string', description: 'Optional quantity (e.g. "2", "500g")' },
      },
      required: ['listId', 'title'],
    },
  },
  {
    name: 'shopping_items_update',
    description:
      'Updates a shopping item. Use checked: true to mark as bought, false to unmark. title and quantity can also be changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping item UUID' },
        title: { type: 'string', description: 'New item name' },
        quantity: { type: 'string', description: 'New quantity or null to clear' },
        checked: { type: 'boolean', description: 'Whether the item has been picked up' },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_items_delete',
    description: 'Permanently deletes a shopping item. Irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping item UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleShoppingTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'shopping_lists_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ShoppingListResponse>>(
        'GET',
        `/v1/shopping-lists${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_create': {
      const result = await apiRequest<ShoppingListResponse>('POST', '/v1/shopping-lists', {
        title: args.title,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.status !== undefined) body.status = args.status;
      const result = await apiRequest<ShoppingListResponse>(
        'PATCH',
        `/v1/shopping-lists/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_delete': {
      await apiRequest<void>('DELETE', `/v1/shopping-lists/${args.id}`);
      return JSON.stringify({ message: 'Shopping list deleted successfully' }, null, 2);
    }

    case 'shopping_items_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ShoppingItemResponse>>(
        'GET',
        `/v1/shopping-lists/${args.listId}/items${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_create': {
      const result = await apiRequest<ShoppingItemResponse>(
        'POST',
        `/v1/shopping-lists/${args.listId}/items`,
        { title: args.title, quantity: args.quantity ?? null },
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.quantity !== undefined) body.quantity = args.quantity;
      if (args.checked !== undefined) body.checked = args.checked;
      const result = await apiRequest<ShoppingItemResponse>(
        'PATCH',
        `/v1/shopping-items/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_delete': {
      await apiRequest<void>('DELETE', `/v1/shopping-items/${args.id}`);
      return JSON.stringify({ message: 'Shopping item deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown shopping tool: ${name}`);
  }
}
