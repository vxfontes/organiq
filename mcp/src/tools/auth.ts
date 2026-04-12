import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest, login } from '../client.js';
import type { AuthResponse, MeResponse } from '../types.js';

export const authTools: Tool[] = [
  {
    name: 'auth_me',
    description:
      'Returns the profile of the currently authenticated Organiq user (id, email, displayName, locale, timezone). Use this to confirm which account is connected.',
    inputSchema: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'auth_login',
    description:
      'Logs in to Organiq with email and password, updating the active session token. Useful if you need to switch accounts during a session.',
    inputSchema: {
      type: 'object',
      properties: {
        email: { type: 'string', description: 'User email address' },
        password: { type: 'string', description: 'User password' },
      },
      required: ['email', 'password'],
    },
  },
];

export async function handleAuthTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'auth_me': {
      const result = await apiRequest<MeResponse>('GET', '/v1/me');
      return JSON.stringify(result.user, null, 2);
    }

    case 'auth_login': {
      const result = await login(args.email as string, args.password as string);
      return JSON.stringify(
        { message: 'Login successful', user: result.user },
        null,
        2,
      );
    }

    default:
      throw new Error(`Unknown auth tool: ${name}`);
  }
}
