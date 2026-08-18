---
name: MailGuard
colors:
  surface: '#f8f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f6'
  surface-container: '#edeef0'
  surface-container-high: '#e7e8ea'
  surface-container-highest: '#e1e2e4'
  on-surface: '#191c1e'
  on-surface-variant: '#424752'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f3'
  outline: '#727784'
  outline-variant: '#c2c6d4'
  surface-tint: '#005cbb'
  primary: '#00458f'
  on-primary: '#ffffff'
  primary-container: '#005cbb'
  on-primary-container: '#c7d9ff'
  inverse-primary: '#abc7ff'
  secondary: '#805600'
  on-secondary: '#ffffff'
  secondary-container: '#fdaf00'
  on-secondary-container: '#694600'
  tertiary: '#374859'
  on-tertiary: '#ffffff'
  tertiary-container: '#4f6071'
  on-tertiary-container: '#c8daee'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e2ff'
  primary-fixed-dim: '#abc7ff'
  on-primary-fixed: '#001b3f'
  on-primary-fixed-variant: '#00458f'
  secondary-fixed: '#ffddaf'
  secondary-fixed-dim: '#ffba43'
  on-secondary-fixed: '#281800'
  on-secondary-fixed-variant: '#614000'
  tertiary-fixed: '#d2e4f9'
  tertiary-fixed-dim: '#b7c8dc'
  on-tertiary-fixed: '#0b1d2c'
  on-tertiary-fixed-variant: '#384859'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e1e2e4'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.5px
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 16px
  gutter-mobile: 12px
---

## Brand & Style
The design system is engineered for efficiency, reliability, and academic focus. It adopts a **Corporate / Modern** aesthetic, specifically leveraging the Material Design 3 (M3) framework to provide a familiar, systematic interface for students managing high-stakes communications. 

The brand personality is "The Calm Assistant"—structured, proactive, and authoritative without being intimidating. The UI minimizes cognitive load by using generous whitespace and clear information density. The emotional goal is to transform the anxiety of a cluttered inbox into a sense of organized progress.

## Colors
The palette is rooted in **Trustworthy Deep Blue**, used for primary actions and brand presence. **Alert Amber** serves as the functional accent, reserved exclusively for high-priority markers and deadline warnings to ensure they break the visual plane.

The design system supports both **Light and Dark modes** using M3 tonal palettes. 
- **Light Mode:** Uses a "Soft Grey" surface (`#F3F4F6`) to reduce stark contrast and eye strain during long reading sessions.
- **Dark Mode:** Transitions to deep charcoal surfaces, utilizing primary-tinted overlays to maintain depth.
- **Priority Tags:** Use high-contrast pairings (e.g., Amber text on a 10% Amber container) to ensure instant recognition.

## Typography
This design system utilizes **Inter** for its exceptional legibility on mobile screens and its neutral, professional tone. 

- **Headlines:** Use tighter letter-spacing and heavier weights to establish clear section hierarchy.
- **Email Snippets:** Body-md is optimized for the preview text of emails to maximize information density without sacrificing readability.
- **Priority Labels:** All-caps `label-lg` styling is used for priority tags (HIGH, MEDIUM, LOW) to differentiate them from standard UI text.
- **Mobile Scaling:** Headlines scale down on mobile devices (e.g., `headline-lg` reduces to 28px) to ensure no awkward line breaks in long academic subject lines.

## Layout & Spacing
The layout follows a **fluid 4-column grid** on mobile, expanding to 8 columns on tablets. It utilizes an 8pt spatial system for all dimensions.

- **Safe Margins:** A 16px horizontal margin is enforced globally on mobile.
- **Vertical Rhythm:** Email list items are separated by a 2px gap or a subtle divider, while logical sections (e.g., "Today" vs "Yesterday") are separated by 24px.
- **Touch Targets:** All interactive elements maintain a minimum 48x48dp touch area, even if the visual representation is smaller (like a back icon).

## Elevation & Depth
In alignment with M3, this design system uses **Tonal Layers** rather than heavy shadows to define hierarchy.

- **Level 0 (Surface):** The base background of the app.
- **Level 1 (Cards):** Applied to email list items and trackers. These use a slightly lighter/darker tone than the surface with a very soft, 4% opacity ambient shadow.
- **Level 2 (Floating Action Button):** The primary 'Compose' or 'Quick Action' button uses a more pronounced shadow to indicate it sits above the scrollable content.
- **Interactions:** On press, cards should elevate to Level 2 or 3 to provide tactile feedback to the student.

## Shapes
The design system adopts a **Rounded** aesthetic to feel approachable and modern.

- **Cards:** Use `rounded-xl` (16px) or higher for main containers to create a soft, contained look for each email or task.
- **Input Fields:** Follow the M3 "Filled" or "Outlined" style with a 4px (Soft) corner radius to maintain structural integrity.
- **Buttons:** Primary buttons use a fully rounded (Pill) shape to distinguish them from cards.
- **Chips/Badges:** Status badges use a 8px radius to sit comfortably within the 16px radius cards.

## Components
Consistent styling for the core student experience:

- **Email List Cards:** White (light) or Surface-Container (dark) background, 16px corner radius. Feature a vertical 4px color bar on the left edge to indicate status (e.g., Blue for Applied, Red for Rejected).
- **Priority Tags:** High-contrast pill shapes. High Priority uses Alert Amber background with black text.
- **Status Badges:** Compact labels with semi-transparent backgrounds. 
    - *Applied:* Primary Blue.
    - *Interview:* Deep Purple.
    - *Offer:* Forest Green.
- **Deadline Tracker Items:** Progress bars are thin (4px height) and use the Tertiary color for the track, and Secondary Amber for the progress to indicate urgency.
- **Buttons:** 
    - *Primary:* Filled with Trustworthy Blue.
    - *Secondary:* Outlined with Primary Blue.
- **Inputs:** M3-style floating labels with a clear focus state using a 2px border in Primary Blue.