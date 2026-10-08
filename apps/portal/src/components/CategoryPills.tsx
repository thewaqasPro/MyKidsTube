import React from 'react';
import type { Category } from '@/types/video';

interface CategoryPillsProps {
  categories: Category[];
  selectedCategoryId: string;
  onSelectCategory: (id: string) => void;
}

interface CategoryMeta {
  emoji: string;
  label: string;
  activeClass: string;
}

const CATEGORY_META: Record<string, CategoryMeta> = {
  all: {
    emoji: '🌟',
    label: 'All Fun',
    activeClass: 'bg-gradient-to-r from-sky to-sky-hover text-canvas-deep shadow-[0_3px_0_0_#0284C7]',
  },
  shorts: {
    emoji: '⚡',
    label: 'Fun Reels',
    activeClass: 'bg-gradient-to-r from-coral to-coral-hover text-white shadow-[0_3px_0_0_#D93B3E]',
  },
  cartoons: {
    emoji: '🎨',
    label: 'Cartoons',
    activeClass: 'bg-gradient-to-r from-bubblegum to-bubblegum/90 text-white shadow-[0_3px_0_0_#BE185D]',
  },
  learning: {
    emoji: '🚀',
    label: 'Learning & Play',
    activeClass: 'bg-gradient-to-r from-mint to-mint-hover text-white shadow-[0_3px_0_0_#047857]',
  },
  music: {
    emoji: '🎵',
    label: 'Songs & Dance',
    activeClass: 'bg-gradient-to-r from-sun to-sun-hover text-canvas-deep shadow-[0_3px_0_0_#D97706]',
  },
  nature: {
    emoji: '🦁',
    label: 'Animals & Nature',
    activeClass: 'bg-gradient-to-r from-orange-400 to-orange-500 text-white shadow-[0_3px_0_0_#C2410C]',
  },
};

export const CategoryPills: React.FC<CategoryPillsProps> = ({
  categories,
  selectedCategoryId,
  onSelectCategory,
}) => {
  const allCategoryItem: Category = { id: 'all', name: 'All Fun' };
  const allList = [allCategoryItem, ...categories];

  return (
    <div className="sticky top-16 z-30 bg-sidebar/95 backdrop-blur-md border-b border-border shadow-sm">
      <div className="flex items-center gap-2.5 px-4 sm:px-6 py-3 overflow-x-auto no-scrollbar scroll-smooth">
        {allList.map((cat) => {
          const isSelected = selectedCategoryId === cat.id;
          const meta = CATEGORY_META[cat.id] || {
            emoji: '🎈',
            label: cat.name.replace(/^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\s]+/u, '').trim(),
            activeClass: 'bg-gradient-to-r from-violet to-violet-hover text-white shadow-[0_3px_0_0_#7E22CE]',
          };

          return (
            <button
              key={cat.id}
              onClick={() => onSelectCategory(cat.id)}
              className={`flex items-center gap-2 whitespace-nowrap px-4 py-2 rounded-full font-display text-[13.5px] transition-all select-none cursor-pointer shrink-0 ${
                isSelected
                  ? `${meta.activeClass} font-bold scale-[1.03]`
                  : 'bg-surface text-text-secondary border border-border hover:bg-surface-hover hover:text-text-primary font-semibold'
              }`}
            >
              <span className="text-[15px]">{meta.emoji}</span>
              <span>{meta.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
