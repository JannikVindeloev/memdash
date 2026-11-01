import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { ConnectionConfig, DashboardCard } from "./lib/types";
import { DEFAULT_CARD, createId } from "./lib/types";
import { connect, disconnect, isConnected } from "./lib/memgraph";

interface DashboardState {
  connected: boolean;
  connecting: boolean;
  connectionError: string | null;
  connection: ConnectionConfig;
  cards: DashboardCard[];
  selectedCardId: string | null;
  sidebarOpen: boolean;
  connect(config: ConnectionConfig): Promise<boolean>;
  logout(): Promise<void>;
  addCard(): string;
  removeCard(id: string): void;
  updateCard(id: string, patch: Partial<DashboardCard>): void;
  setCardResult(id: string, result: { records: unknown[]; fields: string[]; lastRunAt: string; lastError?: string }): void;
  setLayout(id: string, layout: { x: number; y: number; w: number; h: number }): void;
  selectCard(id: string | null): void;
  toggleSidebar(): void;
}

const defaultConnection: ConnectionConfig = {
  uri: "bolt://localhost:7687",
  username: "",
  password: "",
  database: "memgraph",
};

export const useDashboard = create<DashboardState>()(
  persist(
    (set, get) => ({
      connected: false,
      connecting: false,
      connectionError: null,
      connection: defaultConnection,
      cards: [],
      selectedCardId: null,
      sidebarOpen: true,

      connect: async (config) => {
        set({ connecting: true, connectionError: null, connection: config });
        try {
          await connect(config);
          set({ connected: true, connecting: false });
          return true;
        } catch (e) {
          const message = e instanceof Error ? e.message : String(e);
          set({ connected: false, connecting: false, connectionError: message });
          return false;
        }
      },

      logout: async () => {
        await disconnect();
        set({ connected: false, connectionError: null });
      },

      addCard: () => {
        const id = createId();
        const cards = get().cards;
        const maxBottom = cards.reduce((m, c) => Math.max(m, c.position.y + c.position.h), 0);
        const card: DashboardCard = {
          ...DEFAULT_CARD,
          id,
          title: `Card ${cards.length + 1}`,
          position: { x: (cards.length * 2) % 12, y: maxBottom, w: 6, h: 4 },
        };
        set({ cards: [...cards, card], selectedCardId: id });
        return id;
      },

      removeCard: (id) =>
        set((s) => ({
          cards: s.cards.filter((c) => c.id !== id),
          selectedCardId: s.selectedCardId === id ? null : s.selectedCardId,
        })),

      updateCard: (id, patch) =>
        set((s) => ({
          cards: s.cards.map((c) => (c.id === id ? { ...c, ...patch } : c)),
        })),

      setCardResult: (id, result) =>
        set((s) => ({
          cards: s.cards.map((c) =>
            c.id === id
              ? { ...c, cachedRecords: result.records, cachedFields: result.fields, lastRunAt: result.lastRunAt, lastError: result.lastError }
              : c
          ),
        })),

      setLayout: (id, layout) =>
        set((s) => ({
          cards: s.cards.map((c) => (c.id === id ? { ...c, position: layout } : c)),
        })),

      selectCard: (id) => set({ selectedCardId: id }),
      toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
    }),
    {
      name: "memdash-state",
      partialize: (s) => ({
        connection: s.connection,
        cards: s.cards.map(({ cachedRecords, cachedFields, lastRunAt, lastError, ...rest }) => rest),
      }),
    }
  )
);

export { isConnected };
