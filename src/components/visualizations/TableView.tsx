import { Box, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from "@mui/material";
import { formatCell } from "../../lib/format";

export default function TableView({
  records,
  fields,
}: {
  records: Record<string, unknown>[];
  fields: string[];
}) {
  return (
    <TableContainer sx={{ height: "100%" }}>
      <Table stickyHeader size="small">
        <TableHead>
          <TableRow>
            {fields.map((f) => (
              <TableCell key={f} sx={{ fontWeight: 700, whiteSpace: "nowrap" }}>
                {f}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {records.slice(0, 500).map((row, i) => (
            <TableRow key={i}>
              {fields.map((f) => (
                <TableCell key={f} sx={{ whiteSpace: "nowrap", maxWidth: 320, overflow: "hidden", textOverflow: "ellipsis" }}>
                  {formatCell(row[f])}
                </TableCell>
              ))}
            </TableRow>
          ))}
          {records.length === 0 && (
            <TableRow>
              <TableCell colSpan={Math.max(fields.length, 1)} align="center" sx={{ color: "text.secondary" }}>
                No rows returned
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
