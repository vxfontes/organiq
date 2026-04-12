export interface FlagObject {
  id: string;
  name: string;
  color: string;
}

export interface SubflagObject {
  id: string;
  name: string;
  color: string;
}

export interface InboxItemObject {
  id: string;
  source: 'manual' | 'share' | 'ocr';
  rawText: string;
  rawMediaUrl: string | null;
  status:
    | 'NEW'
    | 'PROCESSING'
    | 'SUGGESTED'
    | 'NEEDS_REVIEW'
    | 'CONFIRMED'
    | 'DISMISSED';
  lastError: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AiSuggestionResponse {
  id: string;
  type: 'task' | 'reminder' | 'event' | 'shopping' | 'note';
  title: string;
  confidence: number;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  needsReview: boolean;
  payload: Record<string, unknown>;
  createdAt: string;
}

export interface InboxItemResponse extends InboxItemObject {
  suggestion: AiSuggestionResponse | null;
}

export interface TaskResponse {
  id: string;
  title: string;
  description: string | null;
  status: 'OPEN' | 'DONE';
  dueAt: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ReminderResponse {
  id: string;
  title: string;
  status: 'OPEN' | 'DONE';
  remindAt: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface EventResponse {
  id: string;
  title: string;
  startAt: string | null;
  endAt: string | null;
  allDay: boolean;
  location: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ShoppingListObject {
  id: string;
  title: string;
  status: 'OPEN' | 'DONE' | 'ARCHIVED';
}

export interface ShoppingListResponse extends ShoppingListObject {
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ShoppingItemResponse {
  id: string;
  list: ShoppingListObject;
  title: string;
  quantity: string | null;
  checked: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  nextCursor: string | null;
}

export interface AuthUser {
  id: string;
  email: string;
  displayName: string;
  locale: string;
  timezone: string;
}

export interface AuthResponse {
  token: string;
  user: AuthUser;
}

export interface MeResponse {
  user: AuthUser;
}

export interface ConfirmResponse {
  type: 'task' | 'reminder' | 'event' | 'shopping';
  task?: TaskResponse;
  reminder?: ReminderResponse;
  event?: EventResponse;
  shoppingList?: ShoppingListResponse;
  shoppingItems?: ShoppingItemResponse[];
}
