export type VisualizationType =
  | "table"
  | "graph"
  | "bar"
  | "line"
  | "pie"
  | "metric"
  | "text"
  | "json";

export interface CardPosition {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface DashboardCard {
  id: string;
  title: string;
  cypher: string;
  visualization: VisualizationType;
  position: CardPosition;
  parameters: Record<string, string>;
  refreshRate: number;
  cachedRecords?: unknown[];
  cachedFields?: string[];
  lastRunAt?: string;
  lastError?: string;
}

export interface ConnectionConfig {
  uri: string;
  username: string;
  password: string;
  database: string;
}

export const DEFAULT_CARD: Omit<DashboardCard, "id"> = {
  title: "New card",
  cypher: "MATCH (n) RETURN count(n) AS nodes",
  visualization: "table",
  position: { x: 0, y: 0, w: 6, h: 4 },
  parameters: {},
  refreshRate: 0,
};

export const VISUALIZATION_OPTIONS: { value: VisualizationType; label: string }[] = [
  { value: "table", label: "Table" },
  { value: "graph", label: "Graph" },
  { value: "bar", label: "Bar chart" },
  { value: "line", label: "Line chart" },
  { value: "pie", label: "Pie chart" },
  { value: "metric", label: "Single value" },
  { value: "text", label: "Text / Markdown" },
  { value: "json", label: "JSON" },
];

export function createId(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}
