export const KidColors = {
  // Primary Playful Brand Accents (Warm & Approachable)
  primary: '#FF5E62', // Wonder Coral (#FF5E62)
  accent: '#FFB300', // Wonder Sun (#FFB300)
  red: '#FF5E62', // Friendly Coral Red
  coral: '#FF5E62', // Warm Playful Coral
  sun: '#FFB300', // Joyful Sunshine Yellow
  sky: '#38BDF8', // Electric Sky Sparkle
  mint: '#10B981', // Nature & Verified Safe Green
  violet: '#A855F7', // Magic Bedtime Violet
  bubblegum: '#F472B6', // Cheerful Bubblegum Pink

  // Background & Surfaces (WonderKids Cosmic Night Fort)
  bgDark: '#0B0F19', // Deep Cosmic Indigo (#0B0F19)
  canvasDark: '#0D1322', // Atmospheric Canvas (#0D1322)
  surfaceDark: '#151D33', // Card Surface (#151D33)
  cardDark: '#151D33', // Rounded Card Base (#151D33)
  cardElevated: '#1D2845', // Elevated Surface (#1D2845)
  borderDark: '#243052', // Cosmic Navy Border (#243052)
  borderSubtle: '#1D2845',

  // Top Category Filter Chips
  chipUnselectedBg: '#151D33',
  chipUnselectedText: '#94A3B8',
  chipSelectedBg: '#38BDF8', // Playful Sky Blue for selected
  chipSelectedText: '#0D1322',

  // Typography Tokens
  textLight: '#FFFFFF', // Pure White Text
  textMuted: '#94A3B8', // Soft Slate Secondary Text
  textTertiary: '#64748B', // Dim Slate Text

  // Overlays, Radii & Badges
  durationBadgeBg: 'rgba(11, 15, 25, 0.87)',
  yellow: '#FFB300',
  green: '#10B981',
  purple: '#A855F7',
  pink: '#F472B6',
} as const;

export type KidColorKey = keyof typeof KidColors;
