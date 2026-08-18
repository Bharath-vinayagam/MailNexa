/**
 * Application-wide constants and enums.
 */

const EMAIL_CATEGORIES = {
  PLACEMENT: 'Placement',
  ACADEMIC: 'Academic',
  PERSONAL: 'Personal',
  PROMOTIONS: 'Promotions',
  OTHERS: 'Others',
};

const EMAIL_PRIORITIES = {
  HIGH: 'High',
  MEDIUM: 'Medium',
  LOW: 'Low',
};

const APPLICATION_STATUSES = {
  APPLIED: 'Applied',
  INTERVIEW: 'Interview',
  OFFER: 'Offer',
  REJECTED: 'Rejected',
};

const USER_ROLES = {
  USER: 'user',
  ADMIN: 'admin',
};

const NOTIFICATION_TYPES = {
  DEADLINE_REMINDER: 'deadline_reminder',
  HIGH_PRIORITY_EMAIL: 'high_priority_email',
  APPLICATION_UPDATE: 'application_update',
  SYSTEM: 'system',
};

const AUDIT_ACTIONS = {
  CREATE: 'CREATE',
  READ: 'READ',
  UPDATE: 'UPDATE',
  DELETE: 'DELETE',
  LOGIN: 'LOGIN',
  LOGOUT: 'LOGOUT',
  SYNC: 'SYNC',
  CLASSIFY: 'CLASSIFY',
  OVERRIDE: 'OVERRIDE',
  REVOKE: 'REVOKE',
};

const AUDIT_RESOURCES = {
  USER: 'User',
  EMAIL: 'Email',
  DEADLINE: 'Deadline',
  APPLICATION: 'Application',
  NOTIFICATION: 'Notification',
  AUTH: 'Auth',
};

const GMAIL_SCOPES = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
];

const PRIORITY_KEYWORDS = {
  HIGH: [
    'urgent', 'interview', 'offer', 'deadline', 'immediately', 'asap',
    'action required', 'important', 'critical', 'last date', 'final reminder',
    'placement', 'selection', 'shortlisted', 'congratulations', 'regret',
  ],
  MEDIUM: [
    'registration', 'exam', 'schedule', 'reminder', 'upcoming', 'event',
    'workshop', 'seminar', 'assignment', 'submission',
  ],
  LOW: [
    'newsletter', 'promotion', 'sale', 'update', 'announcement',
    'weekly digest', 'unsubscribe', 'campus events',
  ],
};

const CATEGORY_KEYWORDS = {
  Placement: [
    'internship', 'job', 'placement', 'career', 'hr', 'hiring', 'campus drive',
    'recruitment', 'interview', 'offer letter', 'onboarding', 'joining', 'application status',
    'assessment', 'coding test', 'aptitude', 'shortlisted', 'selected',
  ],
  Academic: [
    'exam', 'grade', 'assignment', 'submission', 'professor', 'faculty',
    'thesis', 'project', 'result', 'semester', 'registration', 'timetable',
    'university', 'college', 'department', 'lecture', 'tuition', 'fee',
  ],
  Personal: [
    'family', 'friend', 'personal', 'housing', 'accommodation', 'bank',
    'subscription', 'travel', 'health', 'insurance',
  ],
  Promotions: [
    'sale', 'discount', 'offer', 'deal', 'promo', 'subscribe', 'unsubscribe',
    'newsletter', 'marketing', 'advertisement', 'coupon', 'free trial',
  ],
};

const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
};

const PAGINATION_DEFAULTS = {
  PAGE: 1,
  LIMIT: 20,
  MAX_LIMIT: 100,
};

module.exports = {
  EMAIL_CATEGORIES,
  EMAIL_PRIORITIES,
  APPLICATION_STATUSES,
  USER_ROLES,
  NOTIFICATION_TYPES,
  AUDIT_ACTIONS,
  AUDIT_RESOURCES,
  GMAIL_SCOPES,
  PRIORITY_KEYWORDS,
  CATEGORY_KEYWORDS,
  HTTP_STATUS,
  PAGINATION_DEFAULTS,
};
