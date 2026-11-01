import { useDashboard } from "../store";
import { runQuery } from "./memgraph";

export async function runCard(cardId: string): Promise<void> {
  const state = useDashboard.getState();
  const card = state.cards.find((c) => c.id === cardId);
  if (!card || !card.cypher.trim()) return;
  try {
    const result = await runQuery(card.cypher, card.parameters, state.connection.database);
    useDashboard.getState().setCardResult(cardId, {
      records: result.records,
      fields: result.fields,
      lastRunAt: new Date().toISOString(),
    });
  } catch (e) {
    useDashboard.getState().setCardResult(cardId, {
      records: [],
      fields: [],
      lastRunAt: new Date().toISOString(),
      lastError: e instanceof Error ? e.message : String(e),
    });
  }
}
