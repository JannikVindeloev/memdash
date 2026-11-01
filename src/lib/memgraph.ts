import neo4j, { Driver, Session, isNode, isRelationship, isInt, Integer } from "neo4j-driver";
import type { ConnectionConfig } from "./types";

export interface QueryResult {
  records: Record<string, unknown>[];
  fields: string[];
  summary: {
    queryText: string;
    durationMs: number;
    rowCount: number;
  };
}

let driver: Driver | null = null;
let activeConfig: ConnectionConfig | null = null;

export async function connect(config: ConnectionConfig): Promise<void> {
  await disconnect();
  const d = neo4j.driver(
    config.uri,
    neo4j.auth.basic(config.username || "", config.password || ""),
    { disableLosslessIntegers: false }
  );
  try {
    await d.verifyConnectivity();
  } catch (e) {
    await d.close().catch(() => undefined);
    throw e;
  }
  driver = d;
  activeConfig = config;
}

export async function disconnect(): Promise<void> {
  if (driver) {
    await driver.close().catch(() => undefined);
    driver = null;
    activeConfig = null;
  }
}

export function isConnected(): boolean {
  return driver !== null;
}

export function getActiveConfig(): ConnectionConfig | null {
  return activeConfig;
}

function idOf(value: unknown): string | number {
  return isInt(value) ? (value as Integer).toNumber() : String(value);
}

const TEMPORAL_TYPES = new Set(["Date", "DateTime", "LocalDateTime", "LocalTime", "Time", "Duration", "Point"]);

export function toJs(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (isInt(value)) return (value as Integer).toNumber();
  if (Array.isArray(value)) return value.map(toJs);
  if (isNode(value)) {
    return {
      __type: "node",
      __labels: [...value.labels],
      __id: idOf(value.identity),
      properties: toJs(value.properties) as Record<string, unknown>,
    };
  }
  if (isRelationship(value)) {
    return {
      __type: "relationship",
      __relType: value.type,
      __id: idOf(value.identity),
      __start: idOf(value.start),
      __end: idOf(value.end),
      properties: toJs(value.properties) as Record<string, unknown>,
    };
  }
  if (typeof value === "object" && TEMPORAL_TYPES.has((value as object).constructor?.name ?? "")) {
    return String(value);
  }
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = toJs(v);
    }
    return out;
  }
  return value;
}

export function substituteParameters(cypher: string, params: Record<string, string>): string {
  let out = cypher;
  for (const [key, value] of Object.entries(params)) {
    const escaped = String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    out = out.split(`$${key}`).join(`"${escaped}"`);
  }
  return out;
}

export async function runQuery(
  cypher: string,
  params: Record<string, string> = {},
  database?: string
): Promise<QueryResult> {
  if (!driver) throw new Error("Not connected to Memgraph.");
  const session: Session = driver.session({ database: database && database !== "memgraph" ? database : undefined });
  try {
    const started = performance.now();
    const result = session.run(substituteParameters(cypher, params));
    const fields = await result.keys();
    const { records: rawRecords } = await result;
    const durationMs = Math.round(performance.now() - started);
    const records = rawRecords.map((r) => {
      const obj: Record<string, unknown> = {};
      for (const key of r.keys) obj[String(key)] = toJs(r.get(String(key)));
      return obj;
    });
    return {
      records,
      fields,
      summary: { queryText: cypher, durationMs, rowCount: records.length },
    };
  } finally {
    await session.close();
  }
}

export interface GraphData {
  nodes: GraphNodeData[];
  relationships: GraphRelData[];
}

export interface GraphNodeData {
  id: string;
  labels: string[];
  caption: string;
  properties: Record<string, unknown>;
  color: string;
}

export interface GraphRelData {
  id: string;
  source: string;
  target: string;
  type: string;
  properties: Record<string, unknown>;
}

const NODE_PALETTE = ["#3d7bfd", "#19c37d", "#f5a524", "#e5534b", "#a371f7", "#2bb3c0", "#ec6aa8", "#8bc34a"];

function labelColor(labels: string[]): string {
  const key = labels.join("|");
  let hash = 0;
  for (let i = 0; i < key.length; i++) hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
  return NODE_PALETTE[hash % NODE_PALETTE.length];
}

export function extractGraph(records: Record<string, unknown>[]): GraphData {
  const nodeMap = new Map<string, GraphNodeData>();
  const relMap = new Map<string, GraphRelData>();
  const visit = (value: unknown): void => {
    if (!value || typeof value !== "object") return;
    const v = value as Record<string, unknown>;
    if (v.__type === "node") {
      const id = String(v.__id);
      if (!nodeMap.has(id)) {
        const labels = Array.isArray(v.__labels) ? (v.__labels as string[]) : [];
        const props = (v.properties as Record<string, unknown>) ?? {};
        const captionKey = ["name", "title", "label", "id"].find((k) => props[k] !== undefined);
        nodeMap.set(id, {
          id,
          labels,
          caption: captionKey ? String(props[captionKey]) : id,
          properties: props,
          color: labelColor(labels),
        });
      }
      return;
    }
    if (v.__type === "relationship") {
      const id = String(v.__id);
      if (!relMap.has(id)) {
        relMap.set(id, {
          id,
          source: String(v.__start),
          target: String(v.__end),
          type: String(v.__relType),
          properties: (v.properties as Record<string, unknown>) ?? {},
        });
      }
      return;
    }
    for (const val of Object.values(v)) {
      if (Array.isArray(val)) val.forEach(visit);
      else visit(val);
    }
  };
  records.forEach((r) => visit(r));
  for (const rel of relMap.values()) {
    if (!nodeMap.has(rel.source) || !nodeMap.has(rel.target)) {
      relMap.delete(rel.id);
    }
  }
  return { nodes: [...nodeMap.values()], relationships: [...relMap.values()] };
}

export async function seedDemoData(database?: string): Promise<string> {
  const statements = [
    "MATCH (n) DETACH DELETE n",
    `CREATE (a:Person {name: 'Ada Lovelace', born: 1815}),
       (g:Person {name: 'Grace Hopper', born: 1906}),
       (m:Person {name: 'Alan Turing', born: 1912}),
       (k:Person {name: 'Katherine Johnson', born: 1918}),
       (lang1:Language {name: 'Cypher'}),
       (lang2:Language {name: 'Python'}),
       (db:Database {name: 'Memgraph'}),
       (a)-[:KNOWS {since: 1843}]->(g),
       (g)-[:WROTE]->(lang2),
       (a)-[:WROTE]->(lang1),
       (m)-[:KNOWS {since: 1936}]->(a),
       (k)-[:WORKED_ON]->(db),
       (m)-[:WORKED_ON]->(db),
       (g)-[:WORKED_ON]->(db)`,
    `UNWIND range(1, 24) AS h
     CREATE (:Metric {hour: h, requests: toInteger(200 + 180 * sin(h / 24 * 6.28) + rand() * 80), latency: toFloat(round(20 + rand() * 30))})`,
  ];
  for (const s of statements) {
    await runQuery(s, {}, database);
  }
  return "Demo graph created: 4 Person nodes, 3 Language/Database nodes, 24 Metric rows.";
}
