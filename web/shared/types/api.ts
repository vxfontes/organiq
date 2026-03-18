export type Nullable<T> = T | null;

export type CursorListResponse<T> = {
  items: T[];
  nextCursor?: string | null;
};

export type AuthUser = {
  id: string;
  email: string;
  displayName: string;
  locale: string;
  timezone: string;
};

export type AuthResponse = {
  token?: string;
  user: AuthUser;
};

export type ApiErrorResponse = {
  error?: string;
  message?: string;
  requestId?: string;
};

export type FlagRef = {
  id: string;
  name: string;
  color?: string | null;
};

export type SubflagRef = {
  id: string;
  name: string;
  color?: string | null;
};

export type FlagResponse = FlagRef & {
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type SubflagResponse = {
  id: string;
  flag?: FlagRef | null;
  name: string;
  color?: string | null;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type TaskResponse = {
  id: string;
  title: string;
  description?: string | null;
  status: "OPEN" | "DONE" | string;
  dueAt?: string | null;
  flag?: FlagRef | null;
  subflag?: SubflagRef | null;
  createdAt: string;
  updatedAt: string;
};

export type ReminderResponse = {
  id: string;
  title: string;
  status: "OPEN" | "DONE" | string;
  remindAt?: string | null;
  flag?: FlagRef | null;
  subflag?: SubflagRef | null;
  createdAt: string;
  updatedAt: string;
};

export type EventResponse = {
  id: string;
  title: string;
  startAt?: string | null;
  endAt?: string | null;
  allDay: boolean;
  location?: string | null;
  flag?: FlagRef | null;
  subflag?: SubflagRef | null;
  createdAt: string;
  updatedAt: string;
};

export type AgendaResponse = {
  events: EventResponse[];
  tasks: TaskResponse[];
  reminders: ReminderResponse[];
};

export type ShoppingListObject = {
  id: string;
  title: string;
  status: "OPEN" | "DONE" | "ARCHIVED" | string;
};

export type ShoppingListResponse = ShoppingListObject & {
  createdAt: string;
  updatedAt: string;
};

export type ShoppingItemResponse = {
  id: string;
  list?: ShoppingListObject | null;
  title: string;
  quantity?: string | null;
  checked: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type RoutineResponse = {
  id: string;
  title: string;
  description?: string | null;
  recurrenceType: string;
  weekdays: number[];
  startTime: string;
  endTime: string;
  weekOfMonth?: number | null;
  startsOn: string;
  endsOn?: string | null;
  color?: string | null;
  isActive: boolean;
  isCompletedToday: boolean;
  flag?: FlagRef | null;
  subflag?: SubflagRef | null;
  createdAt: string;
  updatedAt: string;
};

export type RoutineTodaySummaryResponse = {
  total: number;
  completed: number;
};

export type RoutineCompletionResponse = {
  id: string;
  routineId: string;
  completedOn: string;
  completedAt: string;
};

export type RoutineActivityDay = {
  date: string;
  isCompleted: boolean;
  isScheduled: boolean;
  isToday: boolean;
  isSkipped: boolean;
  weekdayLabel: string;
};

export type RoutineStreakResponse = {
  currentStreak: number;
  totalCompletions: number;
  streakText: string;
  activity: RoutineActivityDay[];
};

export type NotificationPreferencesResponse = {
  remindersEnabled: boolean;
  reminderAtTime: boolean;
  reminderLeadMins: number[];
  eventsEnabled: boolean;
  eventAtTime: boolean;
  eventLeadMins: number[];
  tasksEnabled: boolean;
  taskAtTime: boolean;
  taskLeadMins: number[];
  routinesEnabled: boolean;
  routineAtTime: boolean;
  routineLeadMins: number[];
  quietHoursEnabled: boolean;
  quietStart?: string | null;
  quietEnd?: string | null;
  dailyDigestEnabled: boolean;
  dailyDigestHour: number;
  updatedAt: string;
};

export type UpdateNotificationPreferencesRequest = {
  remindersEnabled?: boolean;
  reminderAtTime?: boolean;
  reminderLeadMins?: number[];
  eventsEnabled?: boolean;
  eventAtTime?: boolean;
  eventLeadMins?: number[];
  tasksEnabled?: boolean;
  taskAtTime?: boolean;
  taskLeadMins?: number[];
  routinesEnabled?: boolean;
  routineAtTime?: boolean;
  routineLeadMins?: number[];
  quietHoursEnabled?: boolean;
  quietStart?: string | null;
  quietEnd?: string | null;
  dailyDigestEnabled?: boolean;
  dailyDigestHour?: number;
};

export type DailySummaryTokenResponse = {
  token: string;
  url: string;
};

export type NotificationLogResponse = {
  id: string;
  type: string;
  referenceId: string;
  title: string;
  body: string;
  leadMins?: number | null;
  status: string;
  scheduledFor: string;
  sentAt?: string | null;
  readAt?: string | null;
  createdAt: string;
};

export type ActionStatusResponse = {
  status: string;
};

export type HomeTimelineItem = {
  id: string;
  item_type: "task" | "reminder" | "event" | "routine" | string;
  title: string;
  subtitle?: string | null;
  scheduled_time: string;
  end_scheduled_time?: string | null;
  is_completed: boolean;
  is_overdue: boolean;
};

export type HomeInsight = {
  title: string;
  summary: string;
  footer: string;
  is_focus: boolean;
};

export type HomeShoppingPreview = {
  id: string;
  title: string;
  total_items: number;
  pending_items: number;
  preview_items: string[];
};

export type HomeDashboardResponse = {
  day_progress: {
    routines_done: number;
    routines_total: number;
    tasks_done: number;
    tasks_total: number;
    progress_percent: number;
  };
  insight?: HomeInsight | null;
  timeline: HomeTimelineItem[];
  shopping_preview: HomeShoppingPreview[];
  week_density: Record<string, number>;
  focus_tasks: TaskResponse[];
  events_today_count: number;
  reminders_today_count: number;
};

export type InboxSuggestion = {
  id: string;
  type: string;
  title: string;
  confidence?: number | null;
  flag?: FlagRef | null;
  subflag?: SubflagRef | null;
  needsReview: boolean;
  payload: unknown;
  createdAt?: string;
};

export type InboxItemResponse = {
  id: string;
  source: string;
  rawText: string;
  status: string;
  lastError?: string | null;
  suggestion?: InboxSuggestion | null;
  suggestions?: InboxSuggestion[];
};

export type ConfirmInboxRequest = {
  type: string;
  title: string;
  payload: unknown;
  flagId?: string;
  subflagId?: string;
};

export type ConfirmInboxResponse = {
  type: string;
  task?: TaskResponse;
  reminder?: ReminderResponse;
  event?: EventResponse;
  shoppingList?: ShoppingListResponse;
  shoppingItems?: ShoppingItemResponse[];
  routine?: RoutineResponse;
};
