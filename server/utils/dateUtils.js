/**
 * Date manipulation utilities.
 */

/**
 * Returns start of today (00:00:00).
 */
const startOfToday = () => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Returns end of today (23:59:59).
 */
const endOfToday = () => {
  const d = new Date();
  d.setHours(23, 59, 59, 999);
  return d;
};

/**
 * Returns a date N days from now.
 */
const daysFromNow = (days) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
};

/**
 * Returns a date N days ago.
 */
const daysAgo = (days) => {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d;
};

/**
 * Checks if a date is today.
 */
const isToday = (date) => {
  const d = new Date(date);
  const today = new Date();
  return (
    d.getDate() === today.getDate() &&
    d.getMonth() === today.getMonth() &&
    d.getFullYear() === today.getFullYear()
  );
};

/**
 * Checks if a date is in the past.
 */
const isPast = (date) => new Date(date) < new Date();

/**
 * Formats a date as human-readable relative string.
 */
const relativeTime = (date) => {
  const diff = new Date(date) - new Date();
  const absDiff = Math.abs(diff);
  const hours = Math.floor(absDiff / (1000 * 60 * 60));
  const days = Math.floor(hours / 24);

  if (diff < 0) {
    if (hours < 24) return `${hours}h overdue`;
    return `${days}d overdue`;
  }
  if (hours < 1) return 'in < 1h';
  if (hours < 24) return `in ${hours}h`;
  if (days === 1) return 'tomorrow';
  return `in ${days} days`;
};

/**
 * Returns start of week (Monday).
 */
const startOfWeek = () => {
  const d = new Date();
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Returns start of month.
 */
const startOfMonth = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1);
};

module.exports = {
  startOfToday,
  endOfToday,
  daysFromNow,
  daysAgo,
  isToday,
  isPast,
  relativeTime,
  startOfWeek,
  startOfMonth,
};
